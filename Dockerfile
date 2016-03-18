FROM openshift/base-centos7
MAINTAINER Daniel Tschan <tschan@puzzle.ch>

RUN mkdir -p /src/.well-known/acme-challenge && chmod 777 /src/.well-known/acme-challenge
ADD acme_tiny.py /usr/local/bin/acme_tiny.py

EXPOSE 8080

WORKDIR /srv
CMD ["/usr/bin/python", "-m", "SimpleHTTPServer", "8080"]
