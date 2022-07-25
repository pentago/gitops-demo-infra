# Localhost CA & TLS Certificates

1. Add desired FQDN to /etc/hosts 127.0.0.1 line (e.g. _gitops.local_)

2. Generate a signing key pair: `openssl genrsa -out ca.key 2048`

3. Find brew-installed OpenSSL binary path: `brew list openssl | grep bin/openssl`

4. Generate CA, certificate and key:

```sh
/usr/local/Cellar/openssl@3/3.0.5/bin/openssl req -x509 -new -nodes -key ca.key -sha256 -days 3650 -out ca.crt -reqexts v3_req -extensions v3_ca -config /usr/local/etc/openssl/openssl.cnf
```

5. Double-click `ca.crt` and trust it site-wide in Keychain Access or add to OS certificate store via Keychain CLI:

```sh
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ca.crt
```

6. Create and apply cert-manager ClusterIssuer CA secret:

```sh
kubectl create secret tls ca-key-pair --cert=ca.crt --key=ca.key --namespace=cert-manager --dry-run=client -oyaml > ca-secret.yaml
```

Alternatively, you may use the `cert.sh` script to automate all the steps above

```text
## References

- https://cert-manager.io/docs/configuration/ca/
- https://github.com/jetstack/cert-manager/issues/279
```
