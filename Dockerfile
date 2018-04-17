FROM centos:centos7

MAINTAINER Roberto Cangiamila <roberto.cangiamila@par-tec.it>

EXPOSE 9200 9300


#### FIXME - MODIFICARE PERCORSI DI INSTALLAZIONE #####
ENV APP_HOME=/usr/share/elasticsearch
ENV HOME=${APP_HOME}
ENV ES_HOME=${APP_HOME}
ENV ES_VERSION="5.6.8"
ENV ELASTIC_CONTAINER true
ENV PATH ${APP_HOME}/bin:$PATH
ENV JAVA_HOME /usr/lib/jvm/jre-1.8.0-openjdk
ENV ES_DOWNLOAD_URL=https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ES_VERSION}.tar.gz
ENV ES_XPACK_DOWNLOAD_URL=https://artifacts.elastic.co/downloads/packs/x-pack/x-pack-${ES_VERSION}.zip
ENV INGEST_PLUGINS="ingest-user-agent ingest-geoip"

LABEL name="ElasticSearch" \
      io.k8s.display-name="ElasticSearch" \
      io.k8s.description="Provide a ElasticSearch image to run on Red Hat OpenShift" \
      io.openshift.expose-services="9200" \
      io.openshift.tags="elasticseach" \
      version=${ES_VERSION}

RUN yum install -y epel-release

RUN INSTALL_PACKAGES="unzip wget vim-enhanced tzdata nano gettext nss_wrapper curl sed which less java-1.8.0-openjdk-headless" && \
    yum install -y --setopt=tsflags=nodocs $INSTALL_PACKAGES && \
    rpm -V $INSTALL_PACKAGES && \
    yum clean all && \
    rm -rf /var/cache/yum

WORKDIR ${APP_HOME}
    
RUN curl -fsSL ${ES_DOWNLOAD_URL} | \
    tar zx --strip-components=1

RUN set -ex && for esdirs in config data logs; do \
        echo "$esdirs"; \
        mkdir -p ${APP_HOME}/"$esdirs"; \
    done

RUN for PLUGIN in x-pack ${INGEST_PLUGINS}; do \
      ${APP_HOME}/bin/elasticsearch-plugin install --batch "$PLUGIN"; \
    done

COPY bin/ ${APP_HOME}/bin
COPY config/ ${APP_HOME}/config

RUN useradd -m -u 1001 -g 0 -m -s /sbin/nologin -d ${HOME} elasticsearch && \
    cat /etc/passwd > /etc/passwd.template && \
    chmod -R a+rwx ${APP_HOME} && \
    chown -R sonar:0 ${APP_HOME} && \
    chmod -R g=u /etc/passwd

USER 1001

VOLUME ${APP_HOME}/data

ENTRYPOINT [ "run_es" ]
