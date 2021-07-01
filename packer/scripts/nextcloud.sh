#!/bin/bash

set -euo pipefail

set -x

NEXTCLOUD_VERSION=21.0.2

echo "Sleeping for 30 seconds"
sleep 30
echo "Done Sleeping"

install_certbot() {
    # Enable SSL
    sudo a2enmod ssl
    sudo a2ensite default-ssl
    sudo service apache2 reload

    sudo snap install core
    sudo snap refresh core
    sudo snap install --classic certbot
    sudo ln -s /snap/bin/certbot /usr/bin/certbot

    sudo mv /tmp/letsencrypt.sh /usr/local/sbin/
    sudo chown root:root /usr/local/sbin/letsencrypt.sh
    sudo chmod 755 /usr/local/sbin/letsencrypt.sh
    sudo mv /tmp/letsencrypt.service /etc/systemd/system/
}

install_nextcloud() {
    WORKDIR=$(mktemp -d)
    pushd "${WORKDIR}"
    curl -O https://download.nextcloud.com/server/releases/nextcloud-${NEXTCLOUD_VERSION}.tar.bz2
    curl -O https://download.nextcloud.com/server/releases/nextcloud-${NEXTCLOUD_VERSION}.tar.bz2.sha256
    curl -O https://nextcloud.com/nextcloud.asc
    curl -O https://download.nextcloud.com/server/releases/nextcloud-${NEXTCLOUD_VERSION}.tar.bz2.asc

    sha256sum -c nextcloud-${NEXTCLOUD_VERSION}.tar.bz2.sha256 < nextcloud-${NEXTCLOUD_VERSION}.tar.bz2

    gpg --import nextcloud.asc
    gpg --verify nextcloud-${NEXTCLOUD_VERSION}.tar.bz2.asc nextcloud-${NEXTCLOUD_VERSION}.tar.bz2

    tar -xjvf nextcloud-${NEXTCLOUD_VERSION}.tar.bz2
    sudo cp -r nextcloud /var/www
    sudo chown -R www-data:www-data /var/www/nextcloud/
    popd
    rm -rf "${WORKDIR}"
}

configure_apache() {
    CONFIG=$(mktemp)
    cat > "${CONFIG}" <<EOF
<VirtualHost *:80>
  DocumentRoot /var/www/nextcloud/
  ServerName  nextcloud.frodux.in

  <Directory /var/www/nextcloud/>
    Require all granted
    AllowOverride All
    Options FollowSymLinks MultiViews

    <IfModule mod_dav.c>
      Dav off
    </IfModule>
  </Directory>
</VirtualHost>
EOF
    sudo mv "${CONFIG}" /etc/apache2/sites-available/nextcloud.conf
    sudo a2ensite nextcloud.conf
    sudo a2enmod rewrite
    sudo a2enmod headers
    sudo a2enmod env
    sudo a2enmod dir
    sudo a2enmod mime
    sudo service apache2 restart
}

configure_nextcloud() {
    pushd /var/www/nextcloud/
    sudo -u www-data php occ  maintenance:install --database \
        "mysql" --database-name "nextcloud"  --database-user "nextcloud" --database-pass \
        "password" --admin-user "admin" --admin-pass "password"
    # Sets the 2nd domain (1st is localhost) to nextcloud.frodux.in
    sudo -u www-data php occ config:system:set trusted_domains 1 --value=nextcloud.frodux.in
    # Make the URLs Pretty
    sudo -u www-data php occ config:system:set overwrite.cli.url --value='https://nextcloud.frodux.in/'
    sudo -u www-data php occ config:system:set htaccess.RewriteBase --value='/'
    sudo -u www-data php /var/www/nextcloud/occ maintenance:update:htaccess
}

# Do it
install_nextcloud
# install_certbot
configure_apache
configure_nextcloud
