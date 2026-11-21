ARG IMAGE_NAME=moechs/php-fpm
ARG IMAGE_VERSION=7.4.33

FROM frugan/php-legacy:7.4-fpm-v0.5.1

COPY php/conf.d/ /usr/local/etc/php/conf.d/
COPY php/www.conf /usr/local/etc/php-fpm.d/www.conf
