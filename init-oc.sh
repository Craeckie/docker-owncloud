#!/bin/bash

update_config_line() {
    local -r config="$1" option="$2" value="$3"

    # Skip if value is empty.
    if [[ -z "$value" ]]; then
        return
    fi
    
    #echo "$2: $3"

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
    update_config_line "$config" logfile "$OC_LOG"
    #update_config_line "$config" logtimezone "$TIMEZONE"
    
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
    cp "$config" "$config.old"
    update_config_line "$config" dbtype "$DB_TYPE"
    update_config_line "$config" dbhost "$DB_HOST"
    update_config_line "$config" dbname "$DB_NAME"
    update_config_line "$config" dbuser "$DB_USER"
    update_config_line "$config" dbpassword "$DB_PASS"
    update_config_line "$config" dbtableprefix "$DB_TABLE_PREFIX"
    update_config_line "$config" datadirectory "$DATA_DIR"
    update_config_line "$config" "memcache.local" '\\OC\\Memcache\\APCu' # Caching through APCu
    update_config_line "$config" logfile "$OC_LOG"
    #update_config_line "$config" logtimezone "$TIMEZONE"
    diff "$config" "$config.old"
    rm -f "$config.old"
    [[ $? -eq 0 ]] && echo -e "Done !\n" || echo -e "FAILURE\n"
}

# Update the config if the config file exists, otherwise autoconfigure owncloud
if [ -f /var/www/owncloud/config/config.php ]
then
    update_owncloud_config
else
    owncloud_autoconfig
fi
