#! /bin/bash
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
# - "client_CA1_?.pem"  # for each unigue client or client group
#
# Client require:
# - "root_CA1"
# - "client_CA1_?.key"  # for each unique client or client group
# - "client_CA1_?.pem"  # for each unigue client or client group


#if [ "$#" -ne 1 ]
#then
#  echo "Error: No domain name argument provided"
#  echo "Usage: Provide a domain name as an argument"
#  exit 1
#fi


COMMAND=$1
DOMAIN=$2

ROOTCA=root_CA1

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

case $COMMAND in

    root)
        generate_key  ${ROOTCA}
	create_root
	;;

    cert)
	generate_key  ${DOMAIN}
	create_csr_conf
	create_csr
	create_conf4cert
	create_ssl
	rm -f *.conf *.csr *.srl
	;;

    text)
	openssl x509 -text -noout -in $2
	;;

    clean)
	rm -f *.crt *.pem *.csr *.conf *.key *.srl
	;;

esac
