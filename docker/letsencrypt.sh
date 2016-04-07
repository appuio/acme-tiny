#!/bin/sh

set -e

domain="$1"

cd /var/lib/letsencrypt

[ -s account.key ] || openssl genrsa 4096 > account.key
[ -s ${domain}.key ] || openssl genrsa 4096 > ${domain}.key
[ -s ${domain}.csr ] || openssl req -new -sha256 -key ${domain}.key -subj "/CN=${domain}" > ${domain}.csr

if ! [ -s ${domain}.crt ] || ! openssl x509 -checkend 2592000 -noout -in ${domain}.crt; then
  # No valid cert or cert will expire within the next 30 days, renew
  python /usr/local/bin/acme_tiny.py --account-key account.key --csr ${domain}.csr --acme-dir /srv/.well-known/acme-challenge/ >${domain}.crt
fi

/usr/local/bin/insert-certificate.sh -h $domain -c ${domain}.crt -k ${domain}.key
