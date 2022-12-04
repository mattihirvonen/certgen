#!/bin/bash
#
# https://devopscube.com/create-self-signed-certificates-openssl/
# https://www.baeldung.com/openssl-self-signed-cert
#
# MbedTLS / MZ's TLS example appliction requirements:
#
# Server require:
# - "root_CA1.pem"
# - "server_CA1_1.key"
# - "server_CA1_1.pem"
# - "client_CA1_1.pem"
# - "client_CA1_2.pem"
# - "client_CA1_?.pem"  # for each unigue client or client group
#
# Client(s) require:
# - "root_CA1"
# - "client_CA1_?.key"  # for each unique client or client group
# - "client_CA1_?.pem"  # for each unigue client or client group
#
# NOTE Mosquitto (MQTT) configuration:
# - require_certificates – Main setting tells client it needs to supply
#   a certificate when set to true. Default is false
# - use_identity_as_username – When set to true it tells mosquitto
#   not to use the password file but to take the username from the
#   certificate (common name given to certificate when you create it).
#   Default is false


#if [ "$#" -ne 1 ]
#then
#  echo "Error: No domain name argument provided"
#  echo "Usage: Provide a domain name as an argument"
#  exit 1
#fi


COMMAND=$1
ROOTCA=$1
DOMAIN=$2

COUNTRY='FI'
STATE='Uusimaa'
LOCATION='Vantaa'
ORGANIZATION='HomeLab'
ORGANIZATIONUNIT='HomeLab R&D'

BITS=4096

#-----------------------------------------------------------------------------
# Generate Private key
# Collect key generations here in one function to easy change key strength

generate_key() {
    openssl genrsa -out $1.key ${BITS}
}

#-----------------------------------------------------------------------------
# Create root CA & Private key

create_root() {
    openssl req -x509 \
                -sha256 -days 356 \
                -nodes \
                -key ${ROOTCA}.key \
                -subj "/CN=${DOMAIN}/C=${COUNTRY}/L=${LOCATION}" \
                -out ${ROOTCA}.crt

    mv ${ROOTCA}.crt ${ROOTCA}.pem
}

#-----------------------------------------------------------------------------
# Create csr conf

create_csr_conf() {
cat > csr.conf <<EOF
[ req ]
default_bits = ${BITS}
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[ dn ]
C  = ${COUNTRY}
ST = ${STATE}
L  = ${LOCATION}
O  = ${ORGANIZATION}
OU = ${ORGANIZATIONUNIT}
CN = ${DOMAIN}

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = ${DOMAIN}
DNS.2 = www.${DOMAIN}
IP.1 = 127.0.0.1
IP.2 = 192.168.1.5 
IP.3 = 192.168.1.6

EOF
}

#-----------------------------------------------------------------------------
# create CSR request using private key

create_csr() {
    openssl req -new -key ${DOMAIN}.key -out ${DOMAIN}.csr -config csr.conf
}

#-----------------------------------------------------------------------------
# Create a external config file for the certificate

create_conf4cert() {
cat > cert.conf <<EOF

authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${DOMAIN}
DNS.2 = *.${DOMAIN}

EOF
}

#-----------------------------------------------------------------------------
# Create SSl with self signed CA

create_ssl() {
    openssl x509 -req \
        -in ${DOMAIN}.csr \
        -CA ${ROOTCA}.pem -CAkey ${ROOTCA}.key \
        -CAcreateserial -out ${DOMAIN}.crt \
        -days 365 \
        -sha256 -extfile cert.conf

    mv ${DOMAIN}.crt ${DOMAIN}.pem
}

#-----------------------------------------------------------------------------
# Print help

print_help() {
    echo ''
    echo 'Usage:  certgen.sh  [--clean] | [--text certfile] | [rootCAname certName]'
    echo ''
    echo 'Where'
    echo ''
    echo '  rootCAname   Root CA certificate file base name without extension. If file'
    echo '               exist, then use existing file and do not generate new file.'
    echo '  certName     Self signed certificate file base name.'
    echo '               Uses "rootCAname" to sign new certificate file.'
    echo '               File get Common Name (CN) field value same as "certName".'
    echo '               File get DNS field values "certName" and "*.certName".'
    echo '  --text       Print out X509 certificate. "certfile" is full X509'
    echo '               certificate file name with extension.'
    echo '  --clean      Remove all existing certificate information files.'
    echo ''
}

#-----------------------------------------------------------------------------

case $COMMAND in

    -?)      print_help;  exit 0 ;;
    -h)      print_help;  exit 0 ;;
    --help)  print_help;  exit 0 ;;

    --text)  openssl x509 -text -noout -in $2;  exit 0 ;;

    --clean) rm -f *.crt *.pem *.csr *.conf *.key *.srl;  exit 0 ;;

esac


if ! [ -f "${ROOTCA}.key" ]
then
	generate_key  ${ROOTCA}
	create_root
fi


generate_key  ${DOMAIN}
create_csr_conf
create_csr
create_conf4cert
create_ssl
rm -f *.conf *.csr *.srl

