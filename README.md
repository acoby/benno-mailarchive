[![Docker Image CI](https://github.com/acoby/benno-mailarchive/actions/workflows/docker-image.yml/badge.svg)](https://github.com/acoby/benno-mailarchive/actions/workflows/docker-image.yml)

# Benno Mailarchive

This image runs [Benno MailArchiv](http://www.benno-mailarchiv.de/), an audit-proof and conformable to law e-mail retention system, including benno-lib, benno-core, benno-archive, benno-rest-lib, benno-rest, benno-smtp, benno-web and benno-imap.

This repository is a fork of [MMinks Docker Benno Mailarchiv](https://github.com/mminks/docker-benno-mailarchive) to contain some acoby specific extensions and enable automatic rebuild of the image via Github Actions.

# Versions

| Package | Version | Description |
|---------|---------|-------------|
| benno-archive | 2.8.17 | Benno MailArchiv Archiving Application |
| benno-core | 2.8.16 | Benno MailArchiv Core |
| benno-rest | 2.8.16 | Benno MailArchiv REST interface |
| benno-smtp | 2.6.0 | Benno MailArchiv SMTP Interface |
| benno-web | 2.8.17 | Benno MailArchiv web interface |
| benno-imap | 3.0.3-1 | Benno MailArchiv imap connector |

# How to use this image

## Preparations

In order to preserve a valid licence file called *benno.lic*, you need a hostname (fqdn) and a fixed ip address. This approach requires a recent docker version (1.10 at least).

```
docker network create --subnet=172.18.0.0/16 <name of your network>
```

You can choose any valid docker subnet you want.

Next we want to prepare some directories to store data and logfiles.

```
mkdir -p /opt/benno/archive /opt/benno/inbox /opt/benno/logs/benno /opt/benno/logs/apache2
```

Choose target directories of your choice.

## First start

```
docker run \
  -d \
  -h <fqdn> \
  --net <name of your network> \
  --ip 172.18.100.1 \
  -p 8080:80 \
  -p 2500:2500 \
  -e "MAIL_FROM=mailarchive@inoxio.de" \
  -v /opt/benno/archive:/srv/benno/archive \
  -v /opt/benno/inbox:/srv/benno/inbox \
  -v /opt/benno/logs/benno:/var/log/benno \
  -v /opt/benno/logs/apache2:/var/log/apache2 \
  --name benno \
  docker.io/acoby/benno-mailarchive:latest
```

### Retrive required license information

When the docker container starts, it configures the container to match your requirements. Also
it outputs the informations coming from `/etc/init.d/benno-rest info` to give your the license
informations, you need.

Read the docker container log with

```
docker logs benno
```

This produces something like

```
Benno Licence Information
---
Host-Info: 172.18.100.1/benno.inoxio.de
Build-Info: 2016-02-02 16:50:31
---
```

Send this to LWsystems GmbH & Co. KG support (support@benno-mailarchiv.de) and wait for your license file. Once you received your file, go on to the next step.

## Final startup

Stop your possibly running benno container and remove him, too.

```
docker stop benno && docker rm benno
```

Finally, fire it up with

```
docker run \
  -d \
  -h <fqdn> \
  --net <name of your network> \
  --ip 172.18.100.1 \
  -p 8080:80 \
  -p 2500:2500 \
  -e "MAIL_FROM=mailarchive@inoxio.de" \
  -v /opt/benno/archive:/srv/benno/archive \
  -v /opt/benno/inbox:/srv/benno/inbox \
  -v /opt/benno/logs/benno:/var/log/benno \
  -v /opt/benno/logs/apache:/var/log/apache \
  -v /path/to/your/benno.lic:/etc/benno/benno.lic \
  --name benno \
  docker.io/acoby/benno-mailarchive:latest
```

Check that everything is working properly with

```
docker logs -f benno
```

## Environment variables

| Name | Default | Description |
|------|---------|-------------|
| BENNO_MAIL_FROM | benno@localhost | sets MAIL_FROM in /etc/benno-web/benno.conf |
| BENNO_LOG_DIR | /var/log/benno | defines the location of the Benno Log directory |
| BENNO_SHARED_SECRET | random | if not changed, it will be recreated everytime you start the container |
| BENNO_ADMIN_PASSWORD | random | if not changed, it will be recreated everytime you start the container |
| BENNO_SMTP_AUTH_USER | none | If not none, then use this SMTP user for Benno SMTP |
| BENNO_SMTP_AUTH_PASS | none | If not none, then use this SMTP password for Benno SMTP |
| BENNO_SMTP_TLS_ENABLED | false | Enabled TLS option in Benno SMTP |
| BENNO_SMTP_TLS_REQUIRED | false | Requires TLS connection in Benno SMTP |
| BENNO_SMTP_KEYSTORE | /etc/benno-smtp/bennokeystore.jks | Path to Java Keystore for TLS Key |
| BENNO_SMTP_KEYSTORE_PASSWORD | KeystorePassword | Passphrase for Benno SMTP Keystore |
| BENNO_SMTP_KEY_PASSWORD | KeystorePassword | Password for Benno SMTP TLS Key |
| DB_TYPE | sqlite | either `mysql` or `sqlite` |
| DB_HOST | database | the name of the database host |
| DB_PORT | 3306 | the port if used with mysql host |
| DB_NAME | /var/lib/benno-web/bennoweb.sqlite | the database name inside the host or the file name of the sqlite database |
| DB_USER | username | the database user that has access to the database |
| DB_PASS | password | the database user password |
| PHPMYADMIN | off | in case of running a complex docker-compose environment with only on external open port, this will enable a proxy forward on /dbadmin url |


## Docker Compose

```
version: '2.1'

services:
  benno:
    image: mminks/docker-benno-mailarchive
    hostname: benno.inovio.de
    restart: always
    ports:
     - "8080:80"
     - "2500:2500"
    environment:
     - BENNO_MAIL_FROM=mailarchive@inoxio.de
     - BENNO_SHARED_SECRET=random
     - BENNO_ADMIN_PASSWORD=mylittlescret
     - DB_TYPE=sqlite
     - DB_NAME=/var/lib/benno-web/bennoweb.sqlite
    volumes:
      - /opt/benno/archive:/srv/benno/archive
      - /opt/benno/inbox:/srv/benno/inbox
      - /opt/benno/database:/var/lib/benno-web
      - /opt/benno/logs/benno:/var/log/benno
      - /opt/benno/logs/apache:/var/log/apache
      - /opt/benno/benno.lic:/etc/benno/benno.lic
    networks:
      benno:
        ipv4_address: 172.18.100.1

networks:
  benno:
    driver: bridge
    enable_ipv6: false
    ipam:
      driver: default
      config:
      - subnet: 172.18.100.0/24
        gateway: 172.18.100.254
```

## Access benno-web

Access benno-web on port 8080 (or whereever you set it up to - see above) of your docker host. The default username is **admin**. The default password will be generated during setup. Show it with

```
docker logs benno | grep "Benno's admin password"
```

It is possible to specify a password for benno-web's initial admin account with:

```
  -e "BENNO_ADMIN_PASSWORD=admin123"
```

(see "Final startup")

Be sure to use a random password or set a strong one when going live.

# What's next?

Visit [Benno MailArchiv Wiki](https://wiki.benno-mailarchiv.de/index.php/Hauptseite) (german only) if you want to import e-mails or something else.

# Contribution

I welcome any kind of contribution. Fork it or contact me. I appreciate any kind of help.
