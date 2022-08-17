#!/bin/bash

set -e

if [ -n "${MAIL_FROM}" ]; then
  sed -ri -e "s/^MAIL_FROM.*/MAIL_FROM = ${MAIL_FROM}/g" /etc/benno-web/benno.conf
fi

# generating secrets
if [[ -z "$BENNO_SHARED_SECRET" ]]; then
  BENNO_SHARED_SECRET=$(cat /dev/urandom | tr -dc 'A-Z0-9' | fold -w 32 | head -n 1)
fi

if [[ -z "$BENNO_ADMIN_PASSWORD" ]]; then
	BENNO_ADMIN_PASSWORD=$(cat /dev/urandom | tr -dc 'A-Z0-9' | fold -w 12 | head -n 1)
fi

HOSTNAME=$(cat /etc/hostname)

echo "Benno's Hostname: $HOSTNAME"
echo "Benno's Shared Secret: $BENNO_SHARED_SECRET"
echo "Benno's admin password: $BENNO_ADMIN_PASSWORD"

# set secret
echo "Configure Hostname and Secrets"
sed -ri -e "s/^SHARED_SECRET =.*/SHARED_SECRET = ${BENNO_SHARED_SECRET}/g" /etc/benno-web/benno.conf
sed -ri -e "s/^    <sharedSecret>.*<\/sharedSecret>.*/    <sharedSecret>${BENNO_SHARED_SECRET}<\/sharedSecret>/g" /etc/benno/benno.xml
sed -ri -e "s/^myhostname =.*/myhostname = ${HOSTNAME}/g" /etc/postfix/main.cf

# set default admin pasword
echo "Configure Admin User"
benno-useradmin -u admin -p $BENNO_ADMIN_PASSWORD

# set owner and rights of volumes
echo "Set Owner and rights of volumes"
chown -R benno:benno /var/log/benno && chmod 770 /var/log/benno
chown -R root:adm ${APACHE_LOG_DIR} && chmod 750 ${APACHE_LOG_DIR}
chown -R benno:benno /srv/benno/archive /srv/benno/inbox
chmod 755 /srv/benno/archive
chmod 770 /srv/benno/inbox

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
exec /usr/bin/tail -f /var/log/benno/*.log ${APACHE_LOG_DIR}/*.log
