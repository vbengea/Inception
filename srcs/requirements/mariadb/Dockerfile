FROM debian:bullseye

RUN apt update && apt upgrade -y && apt install -y mariadb-server

COPY mariadb/conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf
COPY mariadb/tools/mariadb_setup.sh /usr/local/bin/mariadb_setup.sh
RUN chmod +x /usr/local/bin/mariadb_setup.sh

EXPOSE 3306

VOLUME ["/var/lib/mysql"]

ENTRYPOINT ["mariadb_setup.sh"]

CMD ["mysqld_safe"]