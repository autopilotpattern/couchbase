# Autopilot pattern Couchbase
FROM 		couchbase/server:enterprise-4.0.0

# Install Node.js, similar to
# https://github.com/joyent/docker-node/blob/428d5e69763aad1f2d8f17c883112850535e8290/0.12/Dockerfile
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

# Install the json tool
RUN npm install -g json

# Add Containerbuddy
ENV CONTAINERBUDDY_VER 1.3.0
ENV CONTAINERBUDDY file:///etc/containerbuddy.json

RUN export CB_SHA1=c25d3af30a822f7178b671007dcd013998d9fae1 \
    && curl -Lso /tmp/containerbuddy.tar.gz \
         "https://github.com/joyent/containerbuddy/releases/download/${CONTAINERBUDDY_VER}/containerbuddy-${CONTAINERBUDDY_VER}.tar.gz" \
    && echo "${CB_SHA1}  /tmp/containerbuddy.tar.gz" | sha1sum -c \
    && tar zxf /tmp/containerbuddy.tar.gz -C /bin \
    && rm /tmp/containerbuddy.tar.gz

# Add Containerbuddy configuration files and handlers
COPY etc/containerbuddy.json etc/containerbuddy.json
COPY bin/* /usr/local/bin/

# User and discovery env vars
#ENV COUCHBASE_SERVICE_NAME=${COUCHBASE_SERVICE_NAME:-couchbase}
#ENV CONSUL_HOST=${CONSUL_HOST:-'http://consul:8500'}
#ENV COUCHBASE_USER=${COUCHBASE_USER:-Administrator}
#ENV COUCHBASE_PASS=${COUCHBASE_PASS:-password}

# Metadata
EXPOSE 8091 8092 11207 11210 11211 18091 18092
VOLUME /opt/couchbase/var

CMD ["/bin/containerbuddy",
     "/usr/sbin/runsvdir-start",
     "couchbase-server",
     "--",
     "-noinput" # so we don't get dropped into the erlang shell
]
