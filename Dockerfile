FROM openshift/base-centos7
MAINTAINER Daniel Tschan <tschan@puzzle.ch>

RUN yum install -y openssl && yum clean all && mkdir -p /srv/.well-known/acme-challenge && chmod 777 /srv/.well-known/acme-challenge
ADD acme_tiny.py /usr/local/bin/acme_tiny.py

EXPOSE 8080

WORKDIR /srv
CMD ["/usr/bin/python", "-m", "SimpleHTTPServer", "8080"]
