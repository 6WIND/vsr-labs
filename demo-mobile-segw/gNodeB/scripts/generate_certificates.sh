#!/bin/bash

DESTDIR=/etc/certificates/load-tester
mkdir -p ${DESTDIR}
pushd ${DESTDIR}

# Use OpenSSL, it is mandatory to generate a root CA with the Digital Signature "Key Usage" for the CMPv2 usage
openssl genrsa -out 6WIND_CA.key 2048

cat > csr.conf <<EOF
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[ dn ]
C = FR
O = 6WIND
CN = 6WIND_CA

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS = segw.6wind.com

EOF

openssl req -new -key 6WIND_CA.key -out 6WIND_CA.csr -config csr.conf

cat > cert.conf <<EOF

authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:TRUE
keyUsage = digitalSignature, Certificate Sign, CRL Sign
subjectAltName = @alt_names

[alt_names]
DNS = segw.6wind.com

EOF

openssl x509 -req \
    -in 6WIND_CA.csr \
    -key 6WIND_CA.key \
    -out 6WIND_CA.cer \
    -days 365 \
    -sha256 -extfile cert.conf



openssl pkcs12 -export -password pass:foo123 -out 6WIND_CA.p12 -inkey 6WIND_CA.key -in 6WIND_CA.cer -name 6WIND_CA
chmod 777 6WIND_CA.p12

popd
