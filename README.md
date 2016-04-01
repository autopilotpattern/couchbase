# Autopilot pattern for Couchbase

Read [the blog post](https://www.joyent.com/blog/couchbase-in-docker-containers) and the [Docker Compose yaml](https://github.com/misterbisson/clustered-couchbase-in-containers) to better understand how to use this repo.

This is a Dockerfile, Docker Compose file and shell script that will deploy a Couchbase cluster that can be scaled easily using `docker compose scale couchbase=$n`.

## Prep your environment

1. [Get a Joyent account](https://my.joyent.com/landing/signup/) and [add your SSH key](https://docs.joyent.com/public-cloud/getting-started).
1. Install and configure the [Joyent CloudAPI CLI tools](https://apidocs.joyent.com/cloudapi/#getting-started).
1. [Install Docker](https://docs.docker.com/installation/#installation) and [Docker Compose](https://docs.docker.com/compose/install/).
1. [Configure your Docker CLI and Compose for use with Joyent](https://apidocs.joyent.com/docker):

```
curl -O https://raw.githubusercontent.com/joyent/sdc-docker/master/tools/sdc-docker-setup.sh && chmod +x sdc-docker-setup.sh
 ./sdc-docker-setup.sh -k us-east-1.api.joyent.com <ACCOUNT> ~/.ssh/<PRIVATE_KEY_FILE>
```

## Easy instructions

1. [Clone](git@github.com:misterbisson/clustered-couchbase-in-containers.git) or [download](https://github.com/misterbisson/clustered-couchbase-in-containers/archive/master.zip) this repo.
1. `cd` into the cloned or downloaded directory.
1. Execute `bash start.sh` to start everything up.
1. The Couchbase dashboard should automatically open. Sign in with the user/pass printed in the output of `bash start.sh` to see the working, one-node cluster.
1. Scale the cluster using `docker-compose --project-name=ccic scale up couchbase=$n` and watch the node(s) join the cluster in the Couchbase dashboard.

## Detailed instructions

The [`start.sh` script](https://github.com/misterbisson/clustered-couchbase-in-containers/blob/master/start.sh) automatically does the following:

```bash
docker-compose pull
docker-compose --timeout=120 --project-name=ccic up -d --no-recreate
```

Those Docker Compose commands read the [docker-compose.yml](https://github.com/misterbisson/clustered-couchbase-in-containers/blob/master/docker-compose.yml), which describes the three services in the app. The second command, we can call it `docker-compose up` for short, provisions a single container for each of the services.

The three services include:

- Couchbase, the database at the core of this application
- Consul, to support service discovery and health checking among the different services
- Couchbase Cloud Benchmarks, a benchmarking container to round out the picture

Consul is running in it's default configuration as delivered in [Jeff Lindsay's excellent image](https://registry.hub.docker.com/u/progrium/consul/), but Couchbase is wrapped with a [custom start script that enables the magic here](https://github.com/misterbisson/triton-couchbase/blob/master/bin/triton-bootstrap).

Once the first set of containers is running, the `start.sh` script bootstraps the Couchbase container with the following command:

```bash
docker exec -it ccic_couchbase_1 triton-bootstrap bootstrap benchmark
```
Details of what that command does are described below, but the short story is that it initializes the cluster and creates a bucket, then registers this one node Couchbase service with the Consul container.

Because one Couchbase container can get lonely, it's best to scale it using the following command:

```bash
docker-compose --timeout=120 --project-name=ccic scale couchbase=$COUNT
```

Docker Compose will create new Couchbase containers according to the definition in the [docker-compose.yml](https://github.com/misterbisson/clustered-couchbase-in-containers/blob/master/docker-compose.yml), and when those containers come online they'll check with Consul to see if there's an established cluster. When they find there is, they'll join that cluster and rebalance the data across the new nodes.

## Bootstrapping Couchbase

The [Couchbase bootstrap script](https://github.com/misterbisson/triton-couchbase/blob/master/bin/triton-bootstrap) does the following:

1. Set some environmental variables
1. Wait for the Couchbase daemon to be responsive
1. Check if Couchbase is already configured
    1. The boostrap will exit if so
1. Check if Consul is responsive
    1. The bootstrap will exit if Consul is unreachable
1. Initializes the Couchbase node
1. Check for any arguments passed to the bootstrap script
    1. If the script is manually called with the `bootstrap` argument, it does the following:
        1. Initializes the Couchbase cluster
        1. Creates a data bucket
    1. Otherwise, it will...
        1. Check Consul for an established Couchbase cluster
        1. Join the cluster
        1. Rebalance the cluster
1. Check that the cluster is healthy.
1. Register the service with Consul

## Consul notes

[Bootstrapping](https://www.consul.io/docs/guides/bootstrapping.html), [Consul clusters](https://www.consul.io/intro/getting-started/join.html), and the details about [adding and removing nodes](https://www.consul.io/docs/guides/servers.html). The [CLI](https://www.consul.io/docs/commands/index.html) and [HTTP](https://www.consul.io/docs/agent/http.html) API are also documented.

[Check for registered instances of a named service](https://www.consul.io/docs/agent/http/catalog.html#catalog_service)

```bash
curl -v http://consul:8500/v1/catalog/service/couchbase | json -aH ServiceAddress
```

[Register an instance of a service](https://www.consul.io/docs/agent/http/catalog.html#catalog_register)

```bash
export MYIP=$(ip addr show eth0 | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
curl http://consul:8500/v1/agent/service/register -d "$(printf '{"ID": "couchbase-%s","Name": "couchbase","Address": "%s"}' $MYIP $MYIP)"
```
