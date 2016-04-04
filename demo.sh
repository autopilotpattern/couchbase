#!/bin/bash

export PREFIX=cb
export COMPOSE_TIMEOUTDOCKER_CLIENT_TIMEOUT=300

echo 'Starting Couchbase cluster'

echo
echo 'Pulling the most recent images'
docker-compose pull

echo
echo 'Starting containers'
docker-compose --project-name=${PREFIX} up -d --no-recreate

CONSUL="$(triton ip ${PREFIX}_consul_1):8500"
echo
echo 'Consul is now running'
echo "Dashboard: $CONSUL"
command -v open >/dev/null 2>&1 && `open http://$CONSUL/ui/`

CBDASHBOARD="$(triton ip ${PREFIX}_couchbase_1):8091"
echo
echo 'Couchbase cluster running and bootstrapped'
echo "Dashboard: $CBDASHBOARD"
command -v open >/dev/null 2>&1 && `open http://$CBDASHBOARD/index.html#sec=servers`

echo
echo 'Scaling Couchbase cluster to three nodes'
echo "docker-compose --project-name=$PREFIX scale couchbase=3"
docker-compose --project-name=${PREFIX} scale couchbase=3

echo
echo "Go ahead, try a lucky 7 node cluster:"
echo "docker-compose --project-name=$PREFIX scale couchbase=7"
