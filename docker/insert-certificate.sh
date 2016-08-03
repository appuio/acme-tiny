#!/bin/bash

dryrun=false

while getopts ":h:c:k:d" opt; do
  case $opt in
    h)
      hostname=$OPTARG
      ;;
    c)
      if ! openssl x509 -noout -text -in $OPTARG &>/dev/null; then
        echo "ERROR: Provided file is not a valid certificate." >&2
        exit 1
      else
        cert_file=$OPTARG
      fi
      ;;
    k)
      if ! openssl rsa -noout -text -in $OPTARG &>/dev/null; then
        echo "ERROR: Provided file is not a valid private key." >&2
        exit 1
      else
        key_file=$OPTARG
      fi
      ;;
    d)
      dryrun=true
      ;;
    \?)
      echo "ERROR: Invalid option -$OPTARG." >&2
      exit 1
      ;;
    :)
      echo "ERROR: Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

shift $((OPTIND-1))

showsyntax() {
  echo "Syntax: $0 -h HOSTNAME -c CERTIFICATE_FILE -k KEY_FILE [-d] (dry-run)"
}

if [ -z $hostname ]; then
  echo "ERROR: Option -h is required." >&2
  showsyntax
  exit 1
fi
if [ -z $cert_file ]; then
  echo "ERROR: Option -c is required." >&2
  showsyntax
  exit 1
fi
if [ -z $key_file ]; then
  echo "ERROR: Option -k is required." >&2
  showsyntax
  exit 1
fi

OIFS="$IFS"
IFS=';'

export KUBECONFIG=/tmp/.kubeconfig
oc project openshift >/dev/null

# Get all the necessary information of the the given hostname's route
result=($(oc get --all-namespaces routes --output="jsonpath={range .items[?(@.spec.host==\"$hostname\")]}{.spec.to.name};{.metadata.namespace};{.metadata.name};{.spec}{end}"))
service=${result[0]}
namespace=${result[1]}
route=${result[2]}
termination=$(expr match "${result[3]}" '.*termination:\([a-z]*\)')

IFS="$OIFS"

# Prepare key, cert and ca file to be inserted into json
key=$(sed ':a;N;$!ba;s/\n/\\n/g' $key_file)
cert=$(sed ':a;N;$!ba;s/\n/\\n/g' $cert_file)

issuer=$(openssl x509 -issuer -noout -in $cert_file)
ca_file="/usr/local/letsencrypt/lets-encrypt-x${issuer#issuer= /C=US/O=Let\'s Encrypt/CN=Let\'s Encrypt Authority X}-cross-signed.pem"

if [[ -e $ca_file ]]; then
  ca=$(sed ':a;N;$!ba;s/\n/\\n/g' $ca_file)
else
  echo "ERROR: Could not determine issuing intermediate CA file. Tried \"$ca_file\"." >&2
fi

# Create backup of route's json definition, just in case
if [ ! -e "$route.routebackup.json" ]; then
  oc export --namespace=$namespace routes $route --output=json > $route.routebackup.json
else
  oc export --namespace=$namespace routes $route --output=json > $route.routebackup.json.1
fi

# Modify the existing route
case $termination in
  edge|reencrypt)
    oc export --namespace=$namespace routes $route --output=json | jq " \
    .spec.tls.key=\"${key}\" | \
    .spec.tls.certificate=\"${cert}\" | \
    .spec.tls.caCertificate=\"${ca}\"" > \
    /tmp/$route.new.json
    ;;
  passthrough)
    destination_ca=$(openssl s_client -connect ${hostname}:443 -servername ${hostname} -prexit -showcerts </dev/null 2>/dev/null | sed -nr '/BEGIN\ CERTIFICATE/H;//,/END\ CERTIFICATE/G;s/\n(\n[^\n]*){2}$//p' | sed ':a;N;$!ba;s/\n/\\n/g')

    if [ -n "$destination_ca" ]; then
      oc export --namespace=$namespace routes $route --output=json | jq " \
      .spec.tls.termination=\"reencrypt\" | \
      .spec.tls.key=\"${key}\" | \
      .spec.tls.certificate=\"${cert}\" | \
      .spec.tls.caCertificate=\"${ca}\" | \
      .spec.tls.destinationCACertificate=\"${destination_ca}\"" > \
      /tmp/$route.new.json
    else
      echo "ERROR: Failed to obtain CA from backend. Route not replaced." >&2
      exit 1
    fi
    ;;
  *)
    oc export --namespace=$namespace routes $route --output=json | jq " \
    .spec.tls.termination=\"edge\" | \
    .spec.tls.key=\"${key}\" | \
    .spec.tls.certificate=\"${cert}\" | \
    .spec.tls.caCertificate=\"${ca}\" | \
    .spec.tls.insecureEdgeTerminationPolicy=\"Redirect\"" > \
    /tmp/$route.new.json
    ;;
esac

if $dryrun; then
  echo -e "Dry-run enabled, old route not replaced. New route would look like this:\n"
  cat /tmp/$route.new.json
else
  oc replace --namespace=$namespace routes $route -f /tmp/$route.new.json
fi

