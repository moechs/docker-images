FROM php:8.2.35-fpm

ENV TZ=Asia/Shanghai \
    COMPOSER_ALLOW_SUPERUSER=1

COPY --from=mlocati/php-extension-installer:latest /usr/bin/install-php-extensions /usr/local/bin/
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl git unzip; \
    install-php-extensions \
        mysqli pdo_mysql gd opcache zip bz2 bcmath intl exif gettext \
        sockets pcntl soap imagick redis memcached apcu igbinary; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
COPY php/conf.d/ $PHP_INI_DIR/conf.d/

COPY php/www.conf /usr/local/etc/php-fpm.d/www.conf
