#!/bin/bash

set -e

export BASEDIR=$(dirname $(dirname $(readlink -m $0)))
export ETCD_PORT=4001
export COMPOSE_PROJECT_NAME=infra
export NUM_WORKERS=2

trap ctrl_c INT

function ctrl_c() {
  echo "aborting..."
  exit 1
}

function create_env
{
  cd ${BASEDIR}/swarm

  docker-machine create \
    -d virtualbox \
    etcd-master || docker-machine regenerate-certs -f etcd-master

  export ETCD_IP=$(docker-machine ip etcd-master)


  eval $(docker-machine env etcd-master)
  docker-compose up -d registry
  docker-compose up -d registry_ui
  docker-compose up -d etcd
  eval $(docker-machine env -u)

  docker-machine create \
    -d virtualbox \
    --swarm  --swarm-master \
    --swarm-discovery="etcd://${ETCD_IP}:2379/swarm" \
    --engine-opt "cluster-store=etcd://${ETCD_IP}:2379/store"  \
    --engine-opt "cluster-advertise=eth1:2376"  \
    swarm-master  || docker-machine regenerate-certs -f swarm-master

  for i in $(seq 1 $NUM_WORKERS); do
    docker-machine create \
      -d virtualbox \
      --swarm \
      --swarm-discovery="etcd://${ETCD_IP}:2379/swarm" \
      --engine-opt "cluster-store=etcd://${ETCD_IP}:2379/store" \
      --engine-opt "cluster-advertise=eth1:2376" \
      swarm-node-${i} &
  done;
  wait

  create_ssl_certs
}

function create_ssl_certs
{
  cd ${BASEDIR}/swarm

  openssl genrsa -out certs/key.pem 2048
  openssl req -subj "/" -new -key certs/key.pem -out certs/swarm.csr
  openssl x509 -req -days 365 \
    -in certs/swarm.csr \
    -CA ~/.docker/machine/certs/ca.pem \
    -CAkey ~/.docker/machine/certs/ca-key.pem \
    -out certs/cert.pem -extfile certs/openssl.cnf
  openssl rsa -in certs/key.pem -out certs/key.pem
  rm -f certs/swarm.csr
  cp ~/.docker/machine/certs/ca.pem certs/ca.pem

  docker-machine ssh swarm-master -- sudo rm -rf /tmp/swarm_certs /etc/docker/swarm /etc/docker/swarm_certs
  docker-machine ssh swarm-master -- mkdir -p /tmp/swarm_certs/
  docker-machine scp certs/ca.pem swarm-master:/tmp/swarm_certs/ca.pem
  docker-machine scp certs/cert.pem swarm-master:/tmp/swarm_certs/cert.pem
  docker-machine scp certs/key.pem swarm-master:/tmp/swarm_certs/key.pem
  docker-machine ssh swarm-master -- sudo mv /tmp/swarm_certs /etc/docker/swarm/
  for i in $(seq 1 $NUM_WORKERS); do
    docker-machine ssh swarm-node-${i} -- sudo rm -rf /tmp/swarm_certs /etc/docker/swarm /etc/docker/swarm_certs
    docker-machine ssh swarm-node-${i} -- mkdir -p /tmp/swarm_certs/
    docker-machine scp certs/ca.pem swarm-node-${i}:/tmp/swarm_certs/ca.pem
    docker-machine scp certs/cert.pem swarm-node-${i}:/tmp/swarm_certs/cert.pem
    docker-machine scp certs/key.pem swarm-node-${i}:/tmp/swarm_certs/key.pem
    docker-machine ssh swarm-node-${i} -- sudo mv /tmp/swarm_certs /etc/docker/swarm/
  done
}


function start_env
{
  cd ${BASEDIR}/infratest

  docker-machine start etcd-master || true
  docker-machine regenerate-certs etcd-master -f
  export ETCD_IP=$(docker-machine ip etcd-master)

  eval $(docker-machine env etcd-master)
  docker-compose up -d etcd
  eval $(docker-machine env -u)

  eval $(docker-machine env etcd-master)
  docker-compose up -d skydns
  eval $(docker-machine env -u)

  docker-machine start swarm-master || true
  docker-machine regenerate-certs swarm-master -f

  for i in $(seq 1 $NUM_WORKERS); do
    docker-machine start swarm-node-${i} || true
    docker-machine regenerate-certs swarm-node-${i} -f
  done
}

function ls_env
{
  echo ; echo "Docker machine : swarm-master (global cluster)"
  echo "----------------------------------------------"
  eval $(docker-machine env --swarm swarm-master)
  docker ps -a
  echo "----"
  docker images
  echo "----"
  docker network ls
  eval $(docker-machine env -u)

  echo ; echo "Docker machine : etcd-master"
  echo "----------------------------"
  eval $(docker-machine env etcd-master)
  docker ps -a
  echo "----"
  docker images
  echo "----"
  docker network ls
  eval $(docker-machine env -u)

  echo ; echo "Docker machine : swarm-master (local)"
  echo "-------------------------------------"
  eval $(docker-machine env swarm-master)
  docker ps -a
  echo "----"
  docker images
  echo "----"
  docker network ls
  eval $(docker-machine env -u)

  for i in $(seq 1 $NUM_WORKERS); do
    echo ; echo "Docker machine : swarm-node-${i}"
    echo "--------------------------------"
    eval $(docker-machine env swarm-node-${i})
    docker ps -a
    echo "----"
    docker images
    echo "----"
    docker network ls
    eval $(docker-machine env -u)
  done
  echo
  echo "Set ENV to swarm master Global"
  eval $(docker-machine env --swarm swarm-master)
}

function stop_env
{
  docker-machine stop etcd-master || true
  docker-machine stop swarm-master || true
  for i in $(seq 1 $NUM_WORKERS); do
    docker-machine stop swarm-node-${i} || true
  done

}


function delete_env
{
  for i in $(seq 1 $NUM_WORKERS); do
    docker-machine stop swarm-node-${i} || true
    docker-machine rm -y swarm-node-${i} || true
  done
  docker-machine stop swarm-master || true
  docker-machine rm -y swarm-master || true
  docker-machine stop etcd-master || true
  docker-machine rm -y etcd-master || true
}

function usage
{
  echo "$(basename $0) { create | delete | start | stop | ls}"
  exit 1
}


case "$1" in
  create)
    create_env;
    ;;
  start)
    start_env;
    ;;
  stop)
    stop_env;
    ;;
  ls)
    ls_env;
    ;;
  delete)
    delete_env;
    ;;
  certs)
    create_ssl_certs;
    ;;
  *)
    usage
    ;;
esac
