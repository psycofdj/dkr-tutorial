FROM httpd:2.4
MAINTAINER Xavier MARCELET <xavier@marcelet.com>

ARG http_proxy=""
ARG https_proxy=""

RUN apt-get update && apt-get install -y --force-yes wget

COPY ./conf/proxy.conf /etc/apache2/sites-available/
COPY ./conf/htpasswd   /etc/apache2/
COPY ./entrypoint.sh  /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
RUN a2enmod proxy
RUN a2enmod proxy_http
RUN a2ensite proxy
RUN a2dissite 000-default


EXPOSE 80

ENTRYPOINT ["/docker-entrypoint.sh"]
