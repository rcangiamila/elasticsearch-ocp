FROM centos:centos7

MAINTAINER Roberto Cangiamila <roberto.cangiamila@par-tec.it>

EXPOSE 9200 9300

ENV ES_HOME=/opt/elasticsearch
ENV ES_VERSION="5.6.8"
ENV ELASTIC_CONTAINER true
ENV PATH ${ES_HOME}/bin:$PATH
ENV JAVA_HOME /usr/lib/jvm/jre-1.8.0-openjdk
ENV ES_DOWNLOAD_URL=https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ES_VERSION}.tar.gz
ENV INGEST_PLUGINS="ingest-user-agent ingest-geoip ingest-attachment"
ENV ES_JAVA_OPTS "-Xms512m -Xmx512m"
ENV ES_CLUSTER_NAME=exoplatform-es
ENV ES_NUMBER_OF_MASTERS=1
ENV ES_NETWORK_HOST=0.0.0.0
ENV ES_PUBLISH_HOST=
ENV ES_UNICAST_HOSTS "127.0.0.1, [::1]"

LABEL name="ElasticSearch" \
      io.k8s.display-name="ElasticSearch" \
      io.k8s.description="Provide a ElasticSearch image to run on Red Hat OpenShift" \
      io.openshift.expose-services="9200" \
      io.openshift.tags="elasticsearch" \
      version=${ES_VERSION}

RUN yum install -y epel-release

RUN INSTALL_PACKAGES="unzip wget vim-enhanced tzdata nano gettext nss_wrapper curl sed which less java-1.8.0-openjdk-headless" && \
    yum install -y --setopt=tsflags=nodocs $INSTALL_PACKAGES && \
    rpm -V $INSTALL_PACKAGES && \
    yum clean all && \
    useradd -m -u 1001 -g 0 -m -s /sbin/nologin -d ${ES_HOME} elasticsearch && \
    cat /etc/passwd > /etc/passwd.template 

WORKDIR ${ES_HOME}

USER elasticsearch
    
RUN curl -fsSL ${ES_DOWNLOAD_URL} | \
    tar zx --strip-components=1

RUN set -ex && for esdirs in config data logs; do \
        mkdir -p "$esdirs"; \
    done

RUN for PLUGIN in x-pack ${INGEST_PLUGINS}; do \
      elasticsearch-plugin install --batch "$PLUGIN"; \
    done

COPY config/elasticsearch.yml ${ES_HOME}/config/
COPY config/log4j2.properties ${ES_HOME}/config/
COPY config/jvm.options ${ES_HOME}/config/
COPY config/x-pack/log4j2.properties ${ES_HOME}/config/x-pack/
COPY bin/run_es ${ES_HOME}/bin/run_es

USER root

RUN chmod -R a+rwx ${ES_HOME} && \
    chown -R elasticsearch:0 ${ES_HOME} && \
    chmod -R g=u /etc/passwd && \
    ulimit -n 65536 && \
    ulimit -u 2048 && \
    echo "*  -  nofile  65536" >> /etc/security/limits.conf

USER 1001

VOLUME ${ES_HOME}/data

ENTRYPOINT [ "run_es" ]
