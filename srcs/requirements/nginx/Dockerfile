FROM debian:bullseye

RUN apt update && apt upgrade -y && apt install -y nginx openssl gettext-base

RUN mkdir -p /var/www/html
RUN echo "<h1>Welcome to NGINX!</h1>" > /var/www/html/index.html

COPY default /etc/nginx/sites-available/default
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 443

ENTRYPOINT ["/entrypoint.sh"]
