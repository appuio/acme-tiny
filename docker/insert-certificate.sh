#!/bin/bash

while getopts ":h:c:k:" opt; do
  case $opt in
    h)
      hostname=$OPTARG
      ;;
    c)
      if ! openssl x509 -noout -text -in $OPTARG &>/dev/null; then
        echo "ERROR: Provided file is not a valid certificate."
        exit 1
      else
        cert_file=$OPTARG
      fi
      ;;
    k)
      if ! openssl rsa -noout -text -in $OPTARG &>/dev/null; then
        echo "ERROR: Provided file is not a valid private key."
        exit 1
      else
        key_file=$OPTARG
      fi
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
  echo "Syntax: $0 -h HOSTNAME -c CERTIFICATE_FILE -k KEY_FILE"
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
IFS=' '

result=$(oc get --all-namespaces routes --output="jsonpath={range .items[?(@.spec.host==\"$hostname\")]}{.spec.to.name} {.metadata.namespace} {.metadata.name}{end}")
arrResult=($result)
service=${arrResult[0]}
namespace=${arrResult[1]}
route=${arrResult[2]}

IFS="$OIFS"

ip=$(oc get --namespace=$namespace services $service --output="jsonpath={.spec.portalIP}")
key=$(sed ':a;N;$!ba;s/\n/\\n/g' $key_file)
cert=$(sed ':a;N;$!ba;s/\n/\\n/g' $cert_file)

ca=$(openssl s_client -connect ${ip}:443 -prexit -showcerts </dev/null 2>/dev/null | sed -nr '/BEGIN\ CERTIFICATE/H;//,/END\ CERTIFICATE/G;s/\n(\n[^\n]*){2}$//p' | sed ':a;N;$!ba;s/\n/\\n/g')

if [ -n "$ca" ]; then
  if [ ! -e "$route.routebackup.json" ]; then
    oc export --namespace=$namespace routes $route --output=json > $route.routebackup.json
  else
    oc export --namespace=$namespace routes $route --output=json > $route.routebackup.json.1
  fi
  oc export --namespace=$namespace routes $route --output=json | \
  jq " \
  .spec.tls.termination=\"reencrypt\" | \
  .spec.tls.key=\"${key}\" | \
  .spec.tls.certificate=\"${cert}\" | \
  .spec.tls.destinationCaCertificate=\"${ca}\"" | \
  oc replace --namespace=$namespace routes $route -f -
fi

