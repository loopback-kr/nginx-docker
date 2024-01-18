FROM nginx:1.25.3 AS builder
ARG NGINX_VERSION 1.25.3

# Install packages
RUN apt update -qq && apt install -qqy \
    gcc \
    libc6-dev \
    make \
    libssl-dev \
    libpcre3-dev \
    zlib1g-dev \
    curl \
    gnupg \
    libxslt-dev \
    libgd-dev \
    libgeoip-dev \
    wget \
    git \
    patch \
  && apt clean && rm -rf /var/lib/apt/lists/*

# Download sources
RUN wget "http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" -O nginx.tar.gz &&\
    git clone https://github.com/chobits/ngx_http_proxy_connect_module /usr/src/ngx_http_proxy_connect_module

# Reuse same cli arguments as the nginx image used to build
RUN CONFARGS=$(nginx -V 2>&1 | sed -n -e 's/^.*arguments: //p') && \
    mkdir -p /usr/src && \ 
	  tar -xzf nginx.tar.gz -C /usr/src
RUN cd /usr/src/nginx-$NGINX_VERSION && \
    patch -p1 < /usr/src/ngx_http_proxy_connect_module/patch/proxy_connect_rewrite_102101.patch && \
    ./configure --with-compat $CONFARGS --add-dynamic-module=/usr/src/ngx_http_proxy_connect_module && \
    make && make install

FROM nginx:1.25.3

COPY --from=builder /usr/local/nginx/modules/ngx_http_proxy_connect_module.so /etc/nginx/modules/ngx_http_proxy_connect_module.so
COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx