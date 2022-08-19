FROM debian:bullseye

LABEL maintainer="Thoralf Rickert-Wendt <trw@acoby.de>"

ARG DEBIAN_FRONTEND=noninteractive
ARG TARGETARCH

ARG VCS_URL
ARG VCS_REF
ARG BUILD_DATE
ARG BUILD_VERSION
ARG BUILD_BRANCH

ENV TZ Europe/Berlin

ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2

ENV BENNO_LOG_DIR /var/log/benno
ENV BENNO_SHARED_SECRET random
ENV BENNO_ADMIN_PASSWORD random
ENV BENNO_MAIL_FROM benno@localhost

ENV BENNO_SMTP_AUTH_USER none
ENV BENNO_SMTP_AUTH_PASS none
ENV BENNO_SMTP_TLS_ENABLED false
ENV BENNO_SMTP_TLS_REQUIRED false
ENV BENNO_SMTP_KEYSTORE /etc/benno-smtp/bennokeystore.jks
ENV BENNO_SMTP_KEYSTORE_PASSWORD KeystorePassword
ENV BENNO_SMTP_KEY_PASSWORD KeystorePassword

ENV DB_TYPE sqlite
ENV DB_HOST database
ENV DB_PORT 3306
ENV DB_NAME /var/lib/benno-web/bennoweb.sqlite
ENV DB_USER username
ENV DB_PASS password

ENV PHPMYADMIN off

RUN apt-get update --allow-releaseinfo-change && apt-get dist-upgrade -y
RUN echo $TZ | tee /etc/timezone && \
    dpkg-reconfigure --frontend noninteractive tzdata && \
		apt-get install -y \
		  wget \
		  dialog \
		  php-mbstring \
		  gnupg && \
		wget -q http://www.benno-mailarchiv.de/download/debian/benno.asc && \
		apt-key add benno.asc && \
		echo "deb http://www.benno-mailarchiv.de/download/debian /" >> /etc/apt/sources.list.d/benno-mailarchive.list && \
		rm -Rf benno.asc && \
    apt-get update && \
		apt-get -y install && \
		  apache2 \
		  php \
		  php-pear \
		  smarty3 \
      benno-lib \
      benno-core \
      benno-archive \
      benno-rest-lib \
      benno-rest \
      benno-smtp \
      benno-imap \
      php-sqlite3 \
      php-curl \
      smarty3 \
      php-pear \
      sqlite3 \
      libdbi-perl \
      libdbd-sqlite3-perl \
      sqlite3 \
      postfix \
      libnet-ldap-perl \
      libterm-readkey-perl \
      libdbd-mysql-perl \
      libcrypt-eksblowfish-perl \
      libdata-entropy-perl && \
    echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d && \
    cd /tmp && apt-get download benno-web && \
    dpkg --unpack benno-web_*.deb && \
    sed -i '/invoke-rc.d apache2 force-reload/d' /var/lib/dpkg/info/benno-web.postinst && \
    dpkg --configure benno-web && \
    rm -Rf /etc/apache2/conf-available/benno.conf /etc/apache2/conf-enabled/benno.conf && \
    rm -Rf /etc/benno-web/apache-2.2.conf /etc/benno-web/apache-2.4.conf && \
    apt-get autoremove --purge && \
    apt-get autoclean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*

COPY docker-entrypoint.sh /benno.sh
COPY etc/ /etc/

EXPOSE 80
EXPOSE 2500

VOLUME ["/srv/benno/archive", "/srv/benno/inbox", "/var/log/apache2", "/var/log/benno", "/var/lib/benno-web"]

CMD /benno.sh
