#!/bin/sh

COMMON_NAME="gitops.local"
OPENSSL=$(brew list openssl | grep bin/openssl)
OPENSSL_PARAMS="-new -nodes -sha256 -days 3650 -reqexts v3_req -extensions v3_ca -config /usr/local/etc/openssl/openssl.cnf"
OPENSSL_SUBJ="/CN=${COMMON_NAME}"
CA_KEY="ca.key"
CA_CERT="ca.crt"

${OPENSSL} genrsa -out ${CA_KEY} 2048
${OPENSSL} req -x509 ${OPENSSL_PARAMS} -subj ${OPENSSL_SUBJ} -key ${CA_KEY} -out ${CA_CERT}

kubectl --dry-run=client create secret tls ca-key-pair --cert=${CA_CERT} --key=${CA_KEY} --namespace=cert-manager -oyaml > ca-secret.yaml
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ${CA_CERT}
