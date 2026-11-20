ARG IMAGE_NAME=moechs/php-fpm
ARG IMAGE_VERSION=8.2.36

FROM frugan/php:8.2.36-fpm

COPY php/conf.d/ /usr/local/etc/php/conf.d/
COPY php/www.conf /usr/local/etc/php-fpm.d/www.conf
