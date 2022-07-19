# Localhost CA & TLS Certificates

* Add desired FQDN to /etc/hosts 127.0.0.1 line: *local.dev*

* Generate a signing key pair: `openssl genrsa -out ca.key 2048`

* Copy OpenSSL config file for editing `cp /etc/ssl/openssl.cnf openssl-with-ca.cnf`

* Add this to the `openssl-with-ca.cnf`:
```
[ v3_ca ]
basicConstraints = critical,CA:TRUE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer:always
```

* Find brew-installed OpenSSL binary path: `brew list openssl | grep bin/openssl`

* Generate CA, certificate and key:
```
/usr/local/Cellar/openssl@3/3.0.2/bin/openssl req -x509 -new -nodes -key ca.key -sha256 -days 3650 -out ca.crt -extensions v3_ca -config openssl-with-ca.cnf
```

* Double-click ca.crt and trust it site-wide in Keychain Access or add via Keychain CLI:
```
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ca.crt
```

* Create and apply cert-manager ClusterIssuer CA secret:
```
kubectl create secret tls ca-key-pair --cert=ca.crt --key=ca.key --namespace=cert-manager --dry-run=client -oyaml > ca-secret.yaml
```

## References:
* https://docs.cert-manager.io/en/release-0.8/tasks/issuers/setup-ca.html#
* https://github.com/jetstack/cert-manager/issues/279