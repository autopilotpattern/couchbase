#!/bin/bash

PREFIX=ccic
export DOCKER_CLIENT_TIMEOUT=300

echo 'Starting Couchbase cluster'

echo
echo 'Pulling the most recent images'
docker-compose pull

echo
echo 'Starting containers'
docker-compose --project-name=$PREFIX up -d --no-recreate --timeout=300

echo
echo -n 'Initilizing cluster.'

sleep 1.3
COUCHBASERESPONSIVE=0
while [ $COUCHBASERESPONSIVE != 1 ]; do
    echo -n '.'

    RUNNING=$(docker inspect "${PREFIX}_couchbase_1" | json -a State.Running)
    if [ "$RUNNING" == "true" ]
    then
        docker exec -it "${PREFIX}_couchbase_1" triton-bootstrap bootstrap benchmark
        let COUCHBASERESPONSIVE=1
    else
        sleep 1.3
    fi
done
echo

CONSUL="$(sdc-listmachines | json -aH -c "'${PREFIX}_consul_1' == this.name" ips.1):8500"
echo
echo 'Consul is now running'
echo "Dashboard: $CONSUL"
command -v open >/dev/null 2>&1 && `open http://$CONSUL/ui/`

CBDASHBOARD="$(sdc-listmachines | json -aH -c "'${PREFIX}_couchbase_1' == this.name" ips.1):8091"
echo
echo 'Couchbase cluster running and bootstrapped'
echo "Dashboard: $CBDASHBOARD"
echo 'The username and password are printed in earlier messages'
command -v open >/dev/null 2>&1 && `open http://$CBDASHBOARD/index.html#sec=servers`

echo
echo 'Scaling Couchbase cluster to three nodes'
echo "docker-compose --project-name=$PREFIX scale couchbase=3"
docker-compose --project-name=$PREFIX scale couchbase=3

echo
echo "Go ahead, try a lucky 7 node cluster:"
echo "docker-compose --project-name=$PREFIX scale couchbase=7"
