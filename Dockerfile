FROM openshift/base-centos7
MAINTAINER Daniel Tschan <tschan@puzzle.ch>

RUN yum install -y epel-release && yum install -y openssl jq golang-bin && yum clean all && mkdir -p /srv/.well-known/acme-challenge /usr/local/letsencrypt && chmod 777 /srv/.well-known/acme-challenge
ADD acme_tiny.py /usr/local/letsencrypt/acme_tiny.py
ADD docker /usr/local/letsencrypt
RUN cd /usr/local/letsencrypt && go build letsencrypt.go sh.go

EXPOSE 8080

WORKDIR /srv
CMD ["/usr/local/letsencrypt/letsencrypt"]
