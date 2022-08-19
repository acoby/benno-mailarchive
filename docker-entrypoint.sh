#!/bin/bash

set -e

HOSTNAME=$(cat /etc/hostname)
echo "Benno's Hostname: $HOSTNAME"

# generating secrets
if [ "_${BENNO_SHARED_SECRET}_" = "_random_" ]; then
  BENNO_SHARED_SECRET=$(cat /dev/urandom | tr -dc 'A-Z0-9' | fold -w 32 | head -n 1)
  echo "Benno's Shared Secret: $BENNO_SHARED_SECRET"
fi

if [ "_${BENNO_ADMIN_PASSWORD}_" = "_random_" ]; then
	BENNO_ADMIN_PASSWORD=$(cat /dev/urandom | tr -dc 'A-Z0-9' | fold -w 12 | head -n 1)
  echo "Benno's admin password: $BENNO_ADMIN_PASSWORD"
fi

# verification
if [[ $BENNO_SHARED_SECRET == *"#"* ]]; then
  echo "Please don't use # in BENNO_SHARED_SECRET"
  exit 1
fi
if [[ $BENNO_ADMIN_PASSWORD == *"#"* ]]; then
  echo "Please don't use # in BENNO_ADMIN_PASSWORD"
  exit 1
fi
if [[ $BENNO_MAIL_FROM == *"#"* ]]; then
  echo "Please don't use # in BENNO_MAIL_FROM"
  exit 1
fi

if [[ $DB_HOST == *"#"* ]]; then
  echo "Please don't use # in DB_HOST"
  exit 1
fi
if [[ $DB_PORT == *"#"* ]]; then
  echo "Please don't use # in DB_PORT"
  exit 1
fi
if [[ $DB_NAME == *"#"* ]]; then
  echo "Please don't use # in DB_NAME"
  exit 1
fi
if [[ $DB_USER == *"#"* ]]; then
  echo "Please don't use # in DB_PASS"
  exit 1
fi
if [[ $DB_PASS == *"#"* ]]; then
  echo "Please don't use # in DB_USER"
  exit 1
fi


# set secret
echo "Configuring /etc/benno/rest.secret"
echo "${BENNO_SHARED_SECRET}" > /etc/benno/rest.secret

echo "Configuring /etc/benno/benno.xml"
sed -i 's#{BENNO_LOG_DIR}#'${BENNO_LOG_DIR}'#' /etc/benno/benno.xml

echo "Configuring /etc/benno/bennoarchive-log4j.xml"
sed -i 's#{BENNO_LOG_DIR}#'${BENNO_LOG_DIR}'#' /etc/benno/bennoarchive-log4j.xml

echo "Configuring /etc/benno/bennorest-log4j.xml"
sed -i 's#{BENNO_LOG_DIR}#'${BENNO_LOG_DIR}'#' /etc/benno/bennorest-log4j.xml

echo "Configuring /etc/benno-imap/imapauth.conf"
sed -i 's#{BENNO_LOG_DIR}#'${BENNO_LOG_DIR}'#' /etc/benno-imap/imapauth.conf
sed -i 's#{DB_TYPE}#'${DB_TYPE}'#' /etc/benno-imap/imapauth.conf
sed -i 's#{DB_HOST}#'${DB_HOST}'#' /etc/benno-imap/imapauth.conf
sed -i 's#{DB_PORT}#'${DB_PORT}'#' /etc/benno-imap/imapauth.conf
sed -i 's#{DB_NAME}#'${DB_NAME}'#' /etc/benno-imap/imapauth.conf
sed -i 's#{DB_USER}#'${DB_USER}'#' /etc/benno-imap/imapauth.conf
sed -i 's#{DB_PASS}#'${DB_PASS}'#' /etc/benno-imap/imapauth.conf

echo "Configuring /etc/benno-imap/imapsync.conf"
sed -i 's#{BENNO_LOG_DIR}#'${BENNO_LOG_DIR}'#' /etc/benno-imap/imapsync.conf
sed -i 's#{DB_TYPE}#'${DB_TYPE}'#' /etc/benno-imap/imapsync.conf
sed -i 's#{DB_HOST}#'${DB_HOST}'#' /etc/benno-imap/imapsync.conf
sed -i 's#{DB_PORT}#'${DB_PORT}'#' /etc/benno-imap/imapsync.conf
sed -i 's#{DB_NAME}#'${DB_NAME}'#' /etc/benno-imap/imapsync.conf
sed -i 's#{DB_USER}#'${DB_USER}'#' /etc/benno-imap/imapsync.conf
sed -i 's#{DB_PASS}#'${DB_PASS}'#' /etc/benno-imap/imapsync.conf

echo "Configuring /etc/benno-smtp/benno-smtp.conf"
sed -i 's#{BENNO_LOG_DIR}#'${BENNO_LOG_DIR}'#' /etc/benno-smtp/benno-smtp.conf

echo "Configuring /etc/benno-smtp/bennosmtp-log4j.xml"
sed -i 's#{BENNO_LOG_DIR}#'${BENNO_LOG_DIR}'#' /etc/benno-smtp/bennosmtp-log4j.xml

echo "Configuring /etc/benno-web/benno.conf"
sed -i 's#{BENNO_MAIL_FROM}#'${BENNO_MAIL_FROM}'#' /etc/benno-web/benno.conf
sed -i 's#{BENNO_SHARED_SECRET}#'${BENNO_SHARED_SECRET}'#' /etc/benno-web/benno.conf
sed -i 's#{BENNO_LOG_DIR}#'${BENNO_LOG_DIR}'#' /etc/benno-web/benno.conf
sed -i 's#{DB_TYPE}#'${DB_TYPE}'#' /etc/benno-web/benno.conf
sed -i 's#{DB_HOST}#'${DB_HOST}'#' /etc/benno-web/benno.conf
sed -i 's#{DB_PORT}#'${DB_PORT}'#' /etc/benno-web/benno.conf
sed -i 's#{DB_NAME}#'${DB_NAME}'#' /etc/benno-web/benno.conf
sed -i 's#{DB_USER}#'${DB_USER}'#' /etc/benno-web/benno.conf
sed -i 's#{DB_PASS}#'${DB_PASS}'#' /etc/benno-web/benno.conf

echo "Configuring /etc/benno-web/rest.conf"
sed -i 's#{BENNO_SHARED_SECRET}#'${BENNO_SHARED_SECRET}'#' /etc/benno-web/rest.conf

echo "Configuring /etc/postfix/main.cf"
sed -ri -e "s/^myhostname =.*/myhostname = ${HOSTNAME}/g" /etc/postfix/main.cf

if [ "_${PHPMYADMIN}_" = "_on_" ]; then
  echo "Enabling local PHPMyAdmin on https://${HOSTNAME}/dbadmin"
  cp /etc/apache2/conf-available/phpmyadmin.conf /etc/apache2/conf-available/phpmyadmin-on.conf
  a2enmod proxy
  a2enmod proxy_http
fi
# a2enmod rewrite
a2enmod headers

# set owner and rights of volumes
echo "Set Owner and rights of volumes"
chown benno:benno /etc/benno/rest.secret
chown root:${APACHE_RUN_GROUP} /etc/benno-web/benno.conf

chown ${APACHE_RUN_USER}:benno /var/lib/benno-web
chmod 770 /var/lib/benno-web

chmod 640 /etc/benno-web/benno.conf
chmod 640 /etc/benno/rest.secret
chown -R benno:benno /srv/benno/archive /srv/benno/inbox
chmod 755 /srv/benno/archive
chmod 770 /srv/benno/inbox

chown benno:benno ${BENNO_LOG_DIR}
chmod 770 ${BENNO_LOG_DIR}
chown -R root:adm ${APACHE_LOG_DIR}
chmod 750 ${APACHE_LOG_DIR}
chmod 755 /etc/init.d/benno*

# set default admin pasword
echo "Configure Admin User"
benno-useradmin -u admin -p $BENNO_ADMIN_PASSWORD

echo "Benno Licence Information"
echo "---"
/etc/init.d/benno-rest info
echo "---"

# starting benno services
echo "Start Benno Rest"
/etc/init.d/benno-rest start
echo "Start Benno Archive"
/etc/init.d/benno-archive start
echo "Start Benno Smtp"
/etc/init.d/benno-smtp start

echo "Start Apache2"
rm -Rf /var/run/apache2
/etc/init.d/apache2 start

echo "Start Postfix"
/etc/init.d/postfix restart

# show logs on default console
echo "Trace Log Files..."
exec /usr/bin/tail -f ${BENNO_LOG_DIR}/*.log ${APACHE_LOG_DIR}/*.log
