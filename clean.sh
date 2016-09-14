#!/bin/bash


export REGISTRY_HOST=""
export proxy=""


function stop_docker
{
  l_name=$1
  l_run_id=$(docker ps -q -f name=${l_name})
  if [ ! -z "${l_run_id}" ]; then
    docker kill ${l_run_id}
  fi

  l_id=$(docker ps -a -q -f name=${l_name})
  if [ ! -z "${l_id}" ]; then
    docker rm -f ${l_id}
  fi
}

stop_docker front
stop_docker proxy
stop_docker my-container


for c_id in $(docker-compose -f docker-compose-ex1.yml ps -q); do
  stop_docker ${c_id}
done


for c_id in $(docker-compose -f docker-compose-ex2.yml ps -q); do
  stop_docker ${c_id}
done


for c_id in $(docker-compose -f docker-compose-ex3.yml ps -q); do
  stop_docker ${c_id}
done


for c_id in $(docker-compose -f docker-compose-ex4.yml ps -q); do
  stop_docker ${c_id}
done

if [ "$1" = "--images" ]; then
  docker rmi xmarcelet/apache-front >/dev/null 2>&1 || true
  docker rmi xmarcelet/apache-proxy >/dev/null 2>&1 || true
  docker rmi ubuntu:latest >/dev/null 2>&1 || true
  docker rmi ubuntu:12.04 >/dev/null 2>&1 || true
fi

rm -rf /tmp/data
