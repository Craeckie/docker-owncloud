#!/bin/bash

# Fix volumes

# Fix apps-volume
if find "$APPS_DIR" -maxdepth 0 -empty | read v; then
    echo -n "Fixing apps-volume in $APPS_DIR... "
    tar -xzf /tmp/owncloud.tar.gz -C "$APPS_DIR" --strip-components=2 core-${OWNCLOUD_VERSION}/apps
    [[ $? -eq 0 ]] && echo "Done !" || echo "FAILURE"
fi

# Fix config-volume
if find "$CONFIG_DIR" -maxdepth 0 -empty | read v; then
    echo -n "Fixing config-volume in $CONFIG_DIR... "
    tar -xzf /tmp/owncloud.tar.gz -C $CONFIG_DIR --strip-components=2 core-${OWNCLOUD_VERSION}/config
    [[ $? -eq 0 ]] && echo "Done !" || echo "FAILURE"
fi
