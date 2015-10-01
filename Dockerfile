FROM base/archlinux

MAINTAINER Philipp Schmitt <philipp@schmitt.co>

# Dependencies
# TODO: Add NFS support
# removed: php-cli php-mysqlnd php-curl php-gmp (php-imagick)
RUN pacman-key --refresh-keys && pacman -Syyu --noconfirm && pacman-db-upgrade
RUN pacman -S --noconfirm --needed cron bzip2 gmp curl php-gd php-pgsql php-sqlite \
    php-pear php-intl php-mcrypt php-ldap  php-apcu base-devel imagemagick \
    php-fpm smbclient nginx supervisor && \
    pacman -Scc <<< 'Y' <<< 'Y'
RUN pecl install imagick && echo 'extension=imagick.so' >> /etc/php/php.ini

ENV OWNCLOUD_VERSION 8.1.3
ENV TIMEZONE UTC

# Fetch ownCloud dist files
ADD https://github.com/owncloud/core/archive/v${OWNCLOUD_VERSION}.tar.gz \
    /tmp/owncloud.tar.gz
ADD https://github.com/owncloud/3rdparty/archive/v${OWNCLOUD_VERSION}.tar.gz \
    /tmp/3rdparty.tar.gz

# Config files and scripts
COPY nginx_nossl.conf /etc/nginx/nginx_nossl.conf
COPY nginx_ssl.conf /etc/nginx/nginx_ssl.conf
COPY php.ini /etc/php5/fpm/php.ini
COPY php-cli.ini /etc/php5/cli/php.ini
COPY cron.conf /etc/owncloud-cron.conf
COPY supervisor-owncloud.conf /etc/supervisor.d/supervisor-owncloud.conf
COPY run.sh /usr/bin/run.sh
COPY occ.sh /usr/bin/occ

# Install ownCloud
RUN mkdir -p /var/www/ && \
    useradd www-data && \
    tar -C /var/www/ -xf /tmp/owncloud.tar.gz && \
    tar -C /var/www/ -xf /tmp/3rdparty.tar.gz && \
    mv /var/www/core-${OWNCLOUD_VERSION} /var/www/owncloud && \
    rmdir /var/www/owncloud/3rdparty && \
    mv /var/www/3rdparty-${OWNCLOUD_VERSION} /var/www/owncloud/3rdparty && \
    chmod +x /usr/bin/run.sh && \
    rm /tmp/owncloud.tar.gz /tmp/3rdparty.tar.gz && \
    su -s /bin/sh www-data -c "crontab /etc/owncloud-cron.conf"

EXPOSE 80 443

VOLUME ["/var/www/owncloud/config", "/var/www/owncloud/data", \
        "/var/www/owncloud/apps", "/var/log/nginx", \
        "/etc/ssl/certs/owncloud.crt", "/etc/ssl/private/owncloud.key"]

WORKDIR /var/www/owncloud
# USER www-data
CMD ["/usr/bin/run.sh"]
