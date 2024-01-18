FROM nginx:1.25.3
ARG NGINX_VERSION 1.25.3

# Install packages
RUN apt update -qq && apt install -qqy \
    build-essential \
    libssl-dev \
    libpcre3-dev \
    zlib1g-dev \
    git \
    && apt clean && rm -rf /var/lib/apt/lists/*

# Build Nginx with ngx_http_proxy_connect_module
RUN curl -LSs http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz -O &&\
    mkdir -p /usr/src &&\
    tar -xzf nginx-${NGINX_VERSION}.tar.gz -C /usr/src &&\
    cd /usr/src/nginx-${NGINX_VERSION} &&\
    git clone https://github.com/chobits/ngx_http_proxy_connect_module /usr/src/ngx_http_proxy_connect_module &&\
    patch -p1 < /usr/src/ngx_http_proxy_connect_module/patch/proxy_connect_rewrite_102101.patch &&\
    ./configure \
      --add-module=/usr/src/ngx_http_proxy_connect_module \
      --sbin-path=/usr/sbin/nginx \
      --prefix=/usr/local/nginx --conf-path=/etc/nginx/nginx.conf \
      --with-http_v2_module \
      --with-http_ssl_module \
      --with-cc-opt='-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -fPIC' &&\
    make && make install &&\
    rm -rf /usr/src

STOPSIGNAL SIGTERM
CMD [ "nginx", "-g", "daemon off;" ]