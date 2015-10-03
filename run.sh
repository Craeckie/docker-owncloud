#!/usr/bin/env bash

set -e

source /usr/bin/init-env.sh

# FIXME: This next check is always true since there are default values to both
# crt and key
# Enable HTTPS if both crt and key are passed
# if [[ -n "$SSL_KEY" && -n "$SSL_CERT" ]]
# then
#     HTTPS_ENABLED=true
# fi


# Initialize volumes
source /usr/bin/init-volumes.sh

# Set up PHP-FPM
source /usr/bin/init-php.sh

# echo "The $DB_TYPE database is listening on ${DB_HOST}:${DB_PORT}"

# Configure Owncloud
source /usr/bin/init-oc.sh


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

# Various Stuff

# Create data directory
mkdir -p "$DATA_DIR"

# Create logfile
touch "$OC_LOG"
chown www-data:www-data "$OC_LOG"

# Fix permissions
echo -n "Fixing permissions... "
chown -R www-data:www-data /var/www/owncloud
[[ $? -eq 0 ]] && echo -e "Done !\n" || echo -e "FAILURE\n"

# Supervisor, cron setup
#[[ $? -eq 0 ]] && echo -e "Done !\n" || echo -e "FAILURE\n"



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

# clean up
rm -f /tmp/owncloud.tar.gz

exec supervisord -n -c /etc/supervisor/supervisord.conf
