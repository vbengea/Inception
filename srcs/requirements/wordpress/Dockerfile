FROM alpine:3.16

# Install required packages
RUN apk update && apk add --no-cache \
    php8 \
    php8-fpm \
    php8-mysqli \
    php8-json \
    php8-curl \
    php8-dom \
    php8-exif \
    php8-fileinfo \
    php8-mbstring \
    php8-openssl \
    php8-xml \
    php8-zip \
    curl

# Configure PHP-FPM
RUN mkdir -p /run/php && \
    sed -i 's/listen = 127.0.0.1:9000/listen = 0.0.0.0:9000/g' /etc/php8/php-fpm.d/www.conf

# Download and configure WordPress
WORKDIR /var/www
RUN curl -O https://wordpress.org/latest.tar.gz && \
    tar -xzf latest.tar.gz && \
    rm latest.tar.gz && \
    chown -R nobody:nobody /var/www/wordpress

# WordPress configuration script
COPY tools/setup.sh /usr/local/bin/setup.sh
RUN chmod +x /usr/local/bin/setup.sh

WORKDIR /var/www/wordpress
EXPOSE 9000

CMD ["/usr/local/bin/setup.sh"]