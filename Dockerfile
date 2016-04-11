# Autopilot pattern Couchbase
FROM couchbase/server:enterprise-4.0.0

# install jq
RUN apt-get update && \
    apt-get install -y \
    jq \
    && rm -rf /var/lib/apt/lists/*

# get Containerbuddy release
ENV CONTAINERBUDDY_VERSION 1.4.0-rc3
ENV CONTAINERBUDDY file:///etc/containerbuddy.json

RUN export CB_SHA1=24a2babaff53e9829bcf4772cfe0462f08838a11 \
    && curl -Lso /tmp/containerbuddy.tar.gz \
         "https://github.com/joyent/containerbuddy/releases/download/${CONTAINERBUDDY_VERSION}/containerbuddy-${CONTAINERBUDDY_VERSION}.tar.gz" \
    && echo "${CB_SHA1}  /tmp/containerbuddy.tar.gz" | sha1sum -c \
    && tar zxf /tmp/containerbuddy.tar.gz -C /bin \
    && rm /tmp/containerbuddy.tar.gz

# Add Containerbuddy configuration files and handlers
COPY etc/containerbuddy.json etc/containerbuddy.json
COPY bin/* /usr/local/bin/

# Metadata
EXPOSE 8091 8092 11207 11210 11211 18091 18092
VOLUME /opt/couchbase/var

CMD ["/bin/containerbuddy", \
     "/usr/sbin/runsvdir-start", \
     "couchbase-server", \
     "--", \
     "-noinput"] # so we don't get dropped into the erlang shell
