#!/usr/bin/env bash

set -e
if [ -n "$DB_HOST" ]; then
    echo "Using parametric configuration" 1>&2
    DB_TYPE=${DB_TYPE:-sqlite}
    DB_HOST=${DB_HOST:-localhost}
    DB_NAME=${DB_NAME:-owncloud}
    DB_USER=${DB_USER:-owncloud}
    DB_PASS=${DB_PASS:-owncloud}
elif [ -n "$MYSQL_PORT_3306_TCP_ADDR" ]; then
    echo "Using link configuration" 1>&2
    DB_TYPE=mysql
    DB_HOST=$MYSQL_PORT_3306_TCP_ADDR
    DB_NAME=${MYSQL_ENV_MYSQL_DATABASE:-owncloud}
    DB_USER=${MYSQL_ENV_MYSQL_USER:-owncloud}
    DB_PASS=${MYSQL_ENV_MYSQL_PASSWORD:-owncloud}
fi
DB_TABLE_PREFIX=${DB_TABLE_PREFIX:-oc_}
ADMIN_USER=${ADMIN_USER:-admin}
ADMIN_PASS=${ADMIN_PASS:-changeme}
DATA_DIR=${DATA_DIR:-/var/www/owncloud/data}

HTTPS_ENABLED=${HTTPS_ENABLED:-false}

# FIXME: This next check is always true since there are default values to both
# crt and key
# Enable HTTPS if both crt and key are passed
# if [[ -n "$SSL_KEY" && -n "$SSL_CERT" ]]
# then
#     HTTPS_ENABLED=true
# fi

# Database vars
# TODO: Add support for Oracle DB (and SQLite?)
if [[ "$DB_PORT_5432_TCP_ADDR" ]]
then
    DB_TYPE=pgsql
    DB_HOST=$DB_PORT_5432_TCP_ADDR
elif [[ "$DB_PORT_3306_TCP_ADDR" ]]
then
    DB_TYPE=mysql
    DB_HOST=$DB_PORT_3306_TCP_ADDR
fi

# echo "The $DB_TYPE database is listening on ${DB_HOST}:${DB_PORT}"

update_config_line() {
    local -r config="$1" option="$2" value="$3"

    # Skip if value is empty.
    if [[ -z "$value" ]]; then
        return
    fi
    
    echo "$2: $3"

    # Check if the option is set.
    if grep "$option" "$config" >/dev/null 2>&1
    then
        # Update existing option
        sed -i "s|\([\"']$option[\"']\s\+=>\).*|\1 '$value',|" "$config"
    else
        # Create autoconfig.php if necessary
        [[ -f "$config" ]] || {
            echo -e '<?php\n$AUTOCONFIG = array (' > "$config"
        }

        # Add to config
        sed -i "s|\(CONFIG\s*=\s*array\s*(\).*|\1\n  '$option' => '$value',|" "$config"
    fi
}

owncloud_autoconfig() {
    echo "Creating autoconfig.php... "
    local -r config=/var/www/owncloud/config/autoconfig.php
    # Remove existing autoconfig
    rm -f "$config"
    update_config_line "$config" dbtype "$DB_TYPE"
    update_config_line "$config" dbhost "$DB_HOST"
    update_config_line "$config" dbname "$DB_NAME"
    update_config_line "$config" dbuser "$DB_USER"
    update_config_line "$config" dbpass "$DB_PASS"
    update_config_line "$config" dbtableprefix "$DB_TABLE_PREFIX"
    update_config_line "$config" adminlogin "$ADMIN_USER"
    update_config_line "$config" adminpass "$ADMIN_PASS"
    update_config_line "$config" datadirectory "$DATA_DIR"
    update_config_line "$config" "memcache.local" '\\OC\\Memcache\\APCu' # Caching through APCu
    
    # Add closing tag
    if ! grep ');' "$config"
    then
        echo ');' >> "$config"
    fi
    [[ $? -eq 0 ]] && echo -e "Done !\n" || echo -e "FAILURE\n"
}

update_owncloud_config() {
    echo "Updating config.php... "
    local -r config=/var/www/owncloud/config/config.php
    update_config_line "$config" dbtype "$DB_TYPE"
    update_config_line "$config" dbhost "$DB_HOST"
    update_config_line "$config" dbname "$DB_NAME"
    update_config_line "$config" dbuser "$DB_USER"
    update_config_line "$config" dbpassword "$DB_PASS"
    update_config_line "$config" dbtableprefix "$DB_TABLE_PREFIX"
    update_config_line "$config" datadirectory "$DATA_DIR"
    update_config_line "$config" "memcache.local" '\\OC\\Memcache\\APCu' # Caching through APCu
    [[ $? -eq 0 ]] && echo -e "Done !\n" || echo -e "FAILURE\n"
}

# Update the config if the config file exists, otherwise autoconfigure owncloud
if [ -f /var/www/owncloud/config/config.php ]
then
    update_owncloud_config
else
    owncloud_autoconfig
fi

update_nginx_config() {
    echo -n "Updating nginx.conf... "
    local -r config=/etc/nginx/nginx.conf
    # mv /etc/nginx/nginx.conf /etc/nginx.orig
    rm /etc/nginx/nginx.conf
    [[ "$HTTPS_ENABLED" == "true" ]] && {
        echo -n "SSL is enabled "
        ln -s /etc/nginx/nginx_ssl.conf /etc/nginx/nginx.conf
    } || {
        echo -n "SSL is disabled! "
        ln -s /etc/nginx/nginx_nossl.conf /etc/nginx/nginx.conf
    }
    [[ $? -eq 0 ]] && echo -e "Done !\n" || echo -e "FAILURE\n"
}
update_nginx_config

# Fix php-fpm environment
fpm_conf_www="/etc/php5/fpm/pool.d/www.conf"
echo "Fixing ENV in $fpm_conf_www... "
echo 'env[HOSTNAME] = $VIRTUAL_HOST' | tee -a "$fpm_conf_www"
echo 'env[PATH] = /usr/local/bin:/usr/bin:/bin' | tee -a "$fpm_conf_www"
echo 'env[TMP] = /tmp' | tee -a "$fpm_conf_www"
echo 'env[TMPDIR] = /tmp' | tee -a "$fpm_conf_www"
echo 'env[TEMP] = /tmp' | tee -a "$fpm_conf_www"
[[ $? -eq 0 ]] && echo -e "Done !\n" || echo -e "FAILURE\n"

# Enable apcu
echo "Enable apc... "
echo 'apc.enable_cli=1' | tee -a /etc/php5/cli/conf.d/20-apcu.ini
[[ $? -eq 0 ]] && echo -e "Done !\n" || echo -e "FAILURE\n"

# Create data directory
mkdir -p "$DATA_DIR"

# Fix permissions
echo "Fixing permissions... "
chown -R www-data:www-data /var/www/owncloud
[[ $? -eq 0 ]] && echo -e "Done !\n" || echo -e "FAILURE\n"

# FIXME: This setup is intended for running supervisord as www-data
# Supervisor setup
# touch /var/run/supervisord.pid
# chown www-data:www-data /var/run/supervisord.pid
# touch /var/log/supervisor/supervisord.log
# chown www-data:www-data /var/log/supervisor/supervisord.log
# mkdir -p /var/log/supervisor
# chown www-data:www-data /var/log/supervisor

# PHP-FPM setup
# touch /var/log/php5-fpm.log
# chown www-data:www-data /var/log/php5-fpm.log

# nginx setup
# mkdir -p /var/log/nginx
# chown www-data:www-data /var/log/nginx

update_timezone() {
    echo -n "Setting timezone to $1... "
    ln -sf "/usr/share/zoneinfo/$1" /etc/localtime
    [[ $? -eq 0 ]] && echo "Done !" || echo "FAILURE"
}
if [[ -n "$TIMEZONE" ]]
then
    update_timezone "$TIMEZONE"
fi

exec supervisord -n -c /etc/supervisor/supervisord.conf
