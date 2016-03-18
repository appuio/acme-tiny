FROM openshift/base-centos7
MAINTAINER Daniel Tschan <tschan@puzzle.ch>

ADD acme_tiny.py /usr/local/bin/acme_tiny.py

EXPOSE 8080

WORKDIR /srv
CMD ["/usr/bin/python", "-m", "SimpleHTTPServer", "8080"]
