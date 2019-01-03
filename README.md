# acme.sh in Docker

[acme.sh](https://github.com/Neilpang/acme.sh) is an ACME protocol client written in sh for automatically issuing certificates from Let's Encrypt.

This is a compatible Docker image for running acme.sh that doesn't want to make me throw up.
It should behave almost exactly the same as the "official" container, but open an issue if you think it doesn't

## Usage

*As a CLI*
```sh
# issue a certificate
docker run --rm -it -v ~/certs:/acme.sh \
    spritsail/acme.sh --issue -d example.com --standalone
```

```sh
# issue a certificate using dnsapi
docker run --rm -it -v ~/certs:/acme.sh -e CF_Email=.. \
    spritsail/acme.sh --issue -d example.com --dns dns_cf ..
```

*As a daemon*
```sh
# start the daemon
docker run --rm -it -v ~/certs:/acme.sh \
    --name=acme.sh \
    spritsail/acme.sh daemon
```
