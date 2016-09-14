FROM registry:latest
MAINTAINER Xavier MARCELET <xavier@marcelet.com>
COPY config.yml /registryv2/config.yml
COPY docker-entrypoint.sh /registryv2/docker-entrypoint.sh
RUN mkdir -p /var/lib/registry/

ENTRYPOINT ["/registryv2/docker-entrypoint.sh"]
