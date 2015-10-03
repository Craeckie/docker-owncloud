#!/bin/bash


# Fix php-fpm environment (only first time)
fpm_conf_www="/etc/php5/fpm/pool.d/www.conf"
function config_fpm() {
    echo "Fixing ENV in $fpm_conf_www... "
    echo "env[HOSTNAME] = $VIRTUAL_HOST" | tee -a "$fpm_conf_www"
    echo 'env[PATH] = /usr/local/bin:/usr/bin:/bin' | tee -a "$fpm_conf_www"
    echo 'env[TMP] = /tmp' | tee -a "$fpm_conf_www"
    echo 'env[TMPDIR] = /tmp' | tee -a "$fpm_conf_www"
    echo 'env[TEMP] = /tmp' | tee -a "$fpm_conf_www"
    echo '; CONFIGURED' | tee -a "$fpm_conf_www"
    [[ $? -eq 0 ]] && echo -e 'Done !\n' || echo -e "FAILURE\n"
}
fpm_tail=`tail -n 1 "$fpm_conf_www"`
if [ "$fpm_tail" != '; CONFIGURED' ]
then
    config_fpm
fi

# Enable apcu
apcu_conf="/etc/php5/cli/conf.d/20-apcu.ini"
function config_apcu() {
    echo "Enable apc... "
    echo 'apc.enable_cli=1' | tee -a "$apcu_conf"
    echo '; CONFIGURED' | tee -a "$apcu_conf"
    [[ $? -eq 0 ]] && echo -e 'Done !\n' || echo -e "FAILURE\n"
}
apcu_tail=`tail -n 1 "$apcu_conf"`
if [ "$apcu_tail" != '; CONFIGURED' ]
then
    config_apcu
fi

