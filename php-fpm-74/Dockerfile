FROM frugan/php-legacy:7.4.33-fpm

RUN install-php-extensions curl dom fileinfo json mbstring openssl sphinx SimpleXML xml zlib

ENV TZ=Asia/Shanghai \
    APP_ENV=production \
    USER_ID=65534 \
    GROUP_ID=65534 \
    PHP_EXTENSIONS=apcu,bz2,calendar,gettext,imagick,ldap,mcrypt,memcached,redis,sockets \
    PHP_INI_DATE__TIMEZONE=Asia/Shanghai \
    PHP_INI_SHORT_OPEN_TAG=On \
    PHP_INI_DISPLAY_ERRORS=Off \
    PHP_INI_HTML_ERRORS=Off \
    PHP_INI_ENABLE_DL=Off \
    PHP_INI_SYS_TEMP_DIR=/tmp \
    PHP_INI_UPLOAD_TMP_DIR=/tmp \
    PHP_INI_SESSION__SAVE_PATH=/tmp \
    PHP_INI_MEMORY_LIMIT=128M \
    PHP_INI_UPLOAD_MAX_FILESIZE=64M \
    PHP_INI_POST_MAX_SIZE=64M \
    PHP_INI_DEFAULT_SOCKET_TIMEOUT=300 \
    PHP_INI_MAX_EXECUTION_TIME=300 \
    PHP_INI_MAX_INPUT_TIME=300 \
    FPM_POOL_PM=dynamic \
    FPM_POOL_PM__MAX_CHILDREN=6 \
    FPM_POOL_PM__START_SERVERS=2 \
    FPM_POOL_PM__MIN_SPARE_SERVERS=1 \
    FPM_POOL_PM__MAX_SPARE_SERVERS=3 \
    FPM_POOL_PM__MAX_REQUESTS=500 \
    FPM_POOL_REQUEST_TERMINATE_TIMEOUT=300
