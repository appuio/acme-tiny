FROM openshift/base-centos7
MAINTAINER Daniel Tschan <tschan@puzzle.ch>

RUN yum install -y epel-release && \
    yum install -y openssl jq golang-bin && \
    yum clean all && \
    mkdir -p /srv/.well-known/acme-challenge /usr/local/letsencrypt /var/lib/letsencrypt && \
    chmod 777 /srv/.well-known/acme-challenge && \
    cd /usr/local/bin && \
    wget https://master.appuio-beta.ch/console/extensions/clients/linux/oc && \
    chmod a+x /usr/local/bin/oc
ADD acme_tiny.py /usr/local/letsencrypt/acme_tiny.py
ADD docker /usr/local/letsencrypt
RUN cd /usr/local/letsencrypt && go build letsencrypt.go sh.go

USER 1001

EXPOSE 8080

WORKDIR /srv
CMD ["/usr/local/letsencrypt/letsencrypt"]
