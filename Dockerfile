# Autopilot pattern Couchbase
FROM 		couchbase/server:enterprise-4.0.0

# install jq
RUN apt-get update && \
    apt-get install -y \
    jq \
    && rm -rf /var/lib/apt/lists/*

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

# Metadata
EXPOSE 8091 8092 11207 11210 11211 18091 18092
VOLUME /opt/couchbase/var

CMD ["/bin/containerbuddy", \
     "/usr/sbin/runsvdir-start", \
     "couchbase-server", \
     "--", \
     "-noinput"] # so we don't get dropped into the erlang shell
