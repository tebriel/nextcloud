#!/bin/bash

set -euo pipefail

set -x

NEXTCLOUD_VERSION=21.0.2

echo "Sleeping for 30 seconds"
sleep 30
echo "Done Sleeping"

install_prereqs() {
    sudo apt-get update
    sudo apt-get install -y apache2 mariadb-server libapache2-mod-php7.4
    sudo apt-get install -y php7.4-gd php7.4-mysql php7.4-curl php7.4-mbstring php7.4-intl
    sudo apt-get install -y php7.4-gmp php7.4-bcmath php-imagick php7.4-xml php7.4-zip
}

bootstrap_database() {
    sudo /etc/init.d/mysql start

    cat > /tmp/create_db.sql<<EOF
CREATE USER 'nextcloud'@'localhost' IDENTIFIED BY 'password';
CREATE DATABASE IF NOT EXISTS nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud'@'localhost';
FLUSH PRIVILEGES;
EOF
    sudo mysql -uroot < /tmp/create_db.sql
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
    sudo -u www-data php occ config:system:set trusted_domains 2 --value=nextcloud.frodux.in
}

# Do it
install_prereqs
bootstrap_database
install_nextcloud
configure_apache
configure_nextcloud
