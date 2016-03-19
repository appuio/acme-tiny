#!/bin/sh

domain="$1"

cd /var/lib/letsencrypt

[ -e ${domain}.key ] || openssl genrsa 4096 > ${domain}.key
[ -e ${domain}.csr ] || openssl req -new -sha256 -key ${domain}.key -subj "/CN=${domain}" > ${domain}.csr

python /usr/local/bin/acme_tiny.py --account-key account.key --csr ${domain}.csr --acme-dir /srv/.well-known/acme-challenge/
