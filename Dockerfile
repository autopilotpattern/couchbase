#
# Triton-optimized Couchbase
#
FROM 		couchbase/server:enterprise-4.0.0-3508
MAINTAINER 	Casey Bisson <casey.bisson@gmail.com>

#
# We started with the 4.0 beta base image, but there are more recent builds available, so...
# update Couchbase to the most recent available build
#
RUN curl -SLO http://latestbuilds.hq.couchbase.com/couchbase-server/sherlock/4050/couchbase-server-enterprise_4.0.0-4050-ubuntu12.04_amd64.deb \
    && dpkg -i couchbase-server-enterprise_4.0.0-4050-ubuntu12.04_amd64.deb

RUN curl -SLO "http://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz" \
	&& curl -SLO "http://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
	&& gpg --verify SHASUMS256.txt.asc \
	&& grep " node-v$NODE_VERSION-linux-x64.tar.gz\$" SHASUMS256.txt.asc | sha256sum -c - \
	&& tar -xzf "node-v$NODE_VERSION-linux-x64.tar.gz" -C /usr/local --strip-components=1 \
	&& rm "node-v$NODE_VERSION-linux-x64.tar.gz" SHASUMS256.txt.asc \
	&& npm install -g npm@"$NPM_VERSION" \
	&& npm cache clear


#
# Install Node.js
# similar to https://github.com/joyent/docker-node/blob/428d5e69763aad1f2d8f17c883112850535e8290/0.12/Dockerfile
#
RUN gpg --keyserver pool.sks-keyservers.net --recv-keys 7937DFD2AB06298B2293C3187D33FF9D0246406D 114F43EE0176B71C7BC219DD50A3051F888C628D

ENV NODE_VERSION 0.12.4
ENV NPM_VERSION 2.10.1

RUN curl -SLO "http://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz" \
	&& curl -SLO "http://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
	&& gpg --verify SHASUMS256.txt.asc \
	&& grep " node-v$NODE_VERSION-linux-x64.tar.gz\$" SHASUMS256.txt.asc | sha256sum -c - \
	&& tar -xzf "node-v$NODE_VERSION-linux-x64.tar.gz" -C /usr/local --strip-components=1 \
	&& rm "node-v$NODE_VERSION-linux-x64.tar.gz" SHASUMS256.txt.asc \
	&& npm install -g npm@"$NPM_VERSION" \
	&& npm cache clear

#
# Install the json tool
#
RUN npm install -g json

#
# Start scripts
#
COPY bin/* /usr/local/bin/

#
# User and discovery env vars
#
ENV COUCHBASE_SERVICE_NAME=${COUCHBASE_SERVICE_NAME:-couchbase}
ENV CONSUL_HOST=${CONSUL_HOST:-'http://consul:8500'}
ENV COUCHBASE_USER=${COUCHBASE_USER:-Administrator}
ENV COUCHBASE_PASS=${COUCHBASE_PASS:-password}

#
# Metadata
#
EXPOSE 8091 8092 11207 11210 11211 18091 18092
VOLUME /opt/couchbase/var
ENTRYPOINT ["triton-start"]
# pass -noinput so it doesn't drop us in the erlang shell
CMD ["couchbase-server", "--", "-noinput"]
