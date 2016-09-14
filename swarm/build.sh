#!/bin/bash

set -e
export BASEDIR=$(dirname $(dirname $(readlink -m $0)))
g_defaultServices="es-master es-client es-data cron-manager kibana apache curator logstash grafana maintenance"
g_args=""
g_env=""

function usage
{
  echo "usage: build.sh --env { infratest | prod | metriksdce | metriksxmt } [ services... ]"
  exit 1
}

function readOptions
{
	while true; do
		case "$1" in
			--env)
				g_env=$2;
				shift 2;;
			--tunnel)
				g_tunnel=1;
				shift 1;;
      --help)
        usage;
        shift;;
			--)
				shift;
				break;;
			*)
				error "internal argument parse error"
				usage;;
		esac
	done
  g_args=$@
}

function __tag_push {
  l_imgName=$1; shift

  docker tag ${DOCKER_NAMESPACE}/${l_imgName} ${DOCKER_REPOSITORY}/${DOCKER_NAMESPACE}/${l_imgName}
  docker push ${DOCKER_REPOSITORY}/${DOCKER_NAMESPACE}/${l_imgName}
}

function __build {
  l_imgName=$1; shift
  l_dir=$1; shift
  l_file=""
  if [ $# -ge 1 ]; then
    l_file="-f $1"; shift
  fi

  docker build -t ${DOCKER_NAMESPACE}/${l_imgName} ${l_file} ${l_dir}
  __tag_push ${l_imgName}
}

function swarm {
  __build swarm ./infratest/swarm_experimental
}

function skydns {
  __build skydns ./infratest/skydns
}

function registrator {
  __build registrator ./infratest/registrator
}

function es-master {
  __build es-master lib/dockerfile-mos-elasticsearch
}

function es-data {
  __build es-data lib/dockerfile-mos-elasticsearch
}

function es-client {
  __build es-client lib/dockerfile-mos-elasticsearch
}

function kibana {
  __build kibana lib/dockerfile-mos-kibana
}

function apache {
  __build apache lib/dockerfile-mos-apache
}

function curator {
  __build curator lib/dockerfile-mos-curator
}

function logstash {
  __build logstash lib/dockerfile-mos-logstash
}

function grafana {
  __build grafana lib/dockerfile-mos-grafana
}

function maintenance {
  __build maintenance lib/dockerfile-mos-maintenance
}

function cron-manager {
  l_imgName=cron-manager
  tar cz --exclude=.git --exclude ./lib --exclude './.*' --exclude infratest . |  \
    docker build -t ${DOCKER_NAMESPACE}/${l_imgName} -f src/dockerfile-mos-cron/Dockerfile -
  __tag_push ${l_imgName}
}

function run
{
  l_services=$@
  cd ${BASEDIR}

  if [ -z "${l_services}" ]; then
    l_services=${g_defaultServices}
  fi

  case "${g_env}" in
    "infratest")
      export ETCD_IP=$(docker-machine ip etcd-master)
      export DOCKER_REPOSITORY=${ETCD_IP}:5000
      export DOCKER_NAMESPACE=metriksondocker
      ;;
    "metriksxmt")
      export DOCKER_REPOSITORY=kedata001.admin.prod.gen00.ke.p.fti.net:443
      export DOCKER_NAMESPACE=xmarcelet
      ;;
    "metriksdce")
      export DOCKER_REPOSITORY=kedata001.admin.prod.gen00.ke.p.fti.net:443
      export DOCKER_NAMESPACE=dchauviere
      ;;
    "prod")
      export DOCKER_REPOSITORY=kedata001.admin.prod.gen00.ke.p.fti.net:443
      export DOCKER_NAMESPACE=metriksondocker
      ;;
    *)
      usage
      ;;
  esac

  eval $(docker-machine env etcd-master)
  for i in $(echo "${l_services}"); do
    $i
  done
}

l_parseResult=`/usr/bin/getopt -o ''\
   	--long env:,help \
		-n "${g_progName}" -- "$@"`
if [ $? != 0 ]; then
	usage
fi

eval set -- "${l_parseResult}"
readOptions "$@"
run "${g_args}"
