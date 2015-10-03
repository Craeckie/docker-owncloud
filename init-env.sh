#!/bin/bash

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
APPS_DIR=${APPS_DIR:-/var/www/owncloud/apps}
CONFIG_DIR=${CONFIG_DIR:-/var/www/owncloud/config}
OC_LOG=${OC_LOG:-/var/log/owncloud.log}

HTTPS_ENABLED=${HTTPS_ENABLED:-false}

