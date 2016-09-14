FROM httpd:2.4
MAINTAINER Xavier MARCELET <xavier@marcelet.com>

ARG http_proxy=""
ARG https_proxy=""

RUN apt-get update && apt-get install -y --force-yes libapache2-mod-php wget

COPY ./conf/demo.conf /etc/apache2/sites-available/
COPY ./www/           /var/www/demo
COPY ./entrypoint.sh  /docker-entrypoint.sh
RUN a2ensite demo
RUN a2dissite 000-default
RUN chmod +x /docker-entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/docker-entrypoint.sh"]
