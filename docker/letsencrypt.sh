#!/bin/sh

set -e

domain="$1"

cd /var/lib/letsencrypt

[ -s account.key ] || openssl genrsa 4096 > account.key
[ -s ${domain}.key ] || openssl genrsa 4096 > ${domain}.key
[ -s ${domain}.csr ] || openssl req -new -sha256 -key ${domain}.key -subj "/CN=${domain}" > ${domain}.csr

if ! [ -s ${domain}.crt ] || ! openssl x509 -checkend 2592000 -noout -in ${domain}.crt; then
  if [ -s ${domain}.crt ]; then
    echo "Renewing certificate for ${domain}"
  else
    echo "Creating certificate for ${domain}"
  fi

  python /usr/local/letsencrypt/acme_tiny.py --account-key account.key --csr ${domain}.csr --acme-dir /srv/.well-known/acme-challenge/ >${domain}.crt
else
  echo "We already have a certificate for ${domain} which is still valid for at least 30 days."
fi

echo "Configuring certificate for requests to https://${domain}/"
/usr/local/letsencrypt/insert-certificate.sh -h $domain -c ${domain}.crt -k ${domain}.key
