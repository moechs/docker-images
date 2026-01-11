FROM alpine:3.22

ENV NGINX_VERSION=1.29.4 TZ=Asia/Shanghai

RUN cd /tmp && apk add --no-cache --virtual .build-deps \
  build-base git libtool wget tar \
  unzip pcre-dev zlib-dev openldap-dev openssl-dev \
  && apk add --no-cache bash pcre zlib openldap openssl \
  && wget -q http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
  && tar xf nginx-${NGINX_VERSION}.tar.gz \
  && cd /tmp/nginx-${NGINX_VERSION} \
  && git clone https://github.com/kvspb/nginx-auth-ldap.git \
  && addgroup -g 601 www \
  && adduser -S -D -H -u 601 -h /var/lib/nginx -s /sbin/nologin -G www -g www www \
  && bash -eu -c ' \
  writeDirs=( \
  /run/nginx \
  /var/log/nginx \
  /var/cache/nginx \
  /var/cache/nginx/client_body_temp \
  /var/cache/nginx/fastcgi_temp \
  /var/cache/nginx/uwsgi_temp \
  /var/cache/nginx/scgi_temp \
  /var/cache/nginx/proxy_temp \
  ); \
  for dir in "${writeDirs[@]}"; do \
  mkdir -p ${dir}; \
  chown -R www:www ${dir}; \
  done' \
  && ./configure \
      --user=www \
      --group=www \
      --prefix=/etc/nginx \
      --sbin-path=/usr/sbin/nginx \
      --conf-path=/etc/nginx/nginx.conf \
      --modules-path=/usr/share/nginx/modules \
      --error-log-path=/var/log/nginx/error.log \
      --pid-path=/run/nginx/nginx.pid \
      --lock-path=/run/nginx/nginx.lock \
      --http-client-body-temp-path=/var/cache/nginx/client_body_temp/ \
      --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp/ \
      --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp/ \
      --http-scgi-temp-path=/var/cache/nginx/scgi_temp/ \
      --http-proxy-temp-path=/var/cache/nginx/proxy_temp/ \
      --with-http_auth_request_module \
      --add-module=nginx-auth-ldap \
      --with-cc-opt="-O3 -flto -fPIC -fPIE -fstack-protector-strong -Wformat -Werror=format-security -Wno-deprecated-declarations -Wno-strict-aliasing" \
      --with-compat \
      --with-ipv6 \
      --with-http_v2_module \
      --with-threads \
  && make && make install \ 
  && apk del .build-deps && rm -rf /tmp/* \
  && ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime \
  && ln -sf /dev/stdout /var/log/nginx/access.log \
  && ln -sf /dev/stdout /var/log/nginx/error.log \
  && mkdir -p /data/web \
  && echo "OK" >/data/web/index.html

COPY nginx.conf /etc/nginx/nginx.conf

WORKDIR /etc/nginx

STOPSIGNAL SIGQUIT

CMD ["/usr/sbin/nginx", "-g", "daemon off;"]
 
