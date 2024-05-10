ARG PHP_VERSION=8.3
ARG COMPOSER_VERSION=2.7.1
ARG NODE_MAJOR=20
ARG DEFAULT_PHP_EXTENSIONS="bcmath exif gd intl opcache pcntl pdo_pgsql pdo_mysql sockets sysvmsg sysvsem sysvshm zip redis amqp"
ARG PHP_EXTENSIONS
ARG APT_PACKAGES="acl cron sudo procps gettext tini mkcert p7zip unzip git nodejs ca-certificates curl gnupg"
ARG DEBIAN_CODENAME=bullseye
ARG INSTALL_PHP_EXTENSION_URL='https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions'

#
# PHP FPM
#
# https://hub.docker.com/_/php
#

FROM docker.io/php:${PHP_VERSION}-fpm-${DEBIAN_CODENAME} AS php-fpm

WORKDIR /srv/app

ARG DEFAULT_PHP_EXTENSIONS
ARG PHP_EXTENSIONS
ARG APT_PACKAGES
ARG COMPOSER_VERSION
ARG NODE_MAJOR
ARG INSTALL_PHP_EXTENSION_URL
ENV INSTALL_PHP_EXTENSION_URL "${INSTALL_PHP_EXTENSION_URL}"
ENV PHP_EXTENSIONS "${DEFAULT_PHP_EXTENSIONS} ${PHP_EXTENSIONS}"
ENV DOCUMENT_ROOT /srv/app/public
ENV SYMFONY_CLI_URL 'https://github.com/symfony-cli/symfony-cli/releases/latest/download/symfony-cli_linux_amd64.tar.gz'
ENV APT_PACKAGES "${APT_PACKAGES}"
ENV COMPOSER_VERSION "${COMPOSER_VERSION}"

# update and install
RUN set -eux ; \
	mkdir /etc/apt/keyrings/ ; \
	apt-get update ; \
	apt-get install -y ca-certificates curl gnupg ; \
	echo 'deb http://deb.debian.org/debian bullseye-backports main contrib non-free' > /etc/apt/sources.list.d/backports.list ; \
	echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" > /etc/apt/sources.list.d/nodesource.list ; \
	(cd /usr/bin && curl -1sLf $SYMFONY_CLI_URL | tar xfz - symfony) ; \
	curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg ; \
	apt-get update -y && apt-get upgrade -y ; \
	apt-get install -y $APT_PACKAGES ; \
	corepack enable ; \
	corepack prepare yarn@stable --activate ; \
	true

# install php extension. see https://github.com/mlocati/docker-php-extension-installer
RUN set -eux ; \
	curl -sSLf -o '/usr/bin/install-php-extensions' $INSTALL_PHP_EXTENSION_URL ; \
	chmod +x '/usr/bin/install-php-extensions' ; \
	install-php-extensions $PHP_EXTENSIONS ; \
	true

# install composer
RUN set -eux ; \
	curl -sSLf -o '/usr/bin/composer' "https://getcomposer.org/download/$COMPOSER_VERSION/composer.phar" ; \
	chmod +x '/usr/bin/composer' ; \
	true

# configurations
RUN set -eux ; \
	mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" ; \
	chsh --shell /bin/bash www-data ; \
	chown www-data /var/www ; \
	mkdir -p '/srv/app/var' ; \
	chmod 777 '/srv/app/var' ; \
	true

# cleanup
RUN set -eux ; \
	rm /etc/cron*/*; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false ; \
	rm -rf /var/lib/apt/lists/*; \
	rm -rf /root/.composer/cache/*; \
	rm -rf /root/.cache; \
	true

#
# PHP ZTS
#

FROM docker.io/php:${PHP_VERSION}-zts-${DEBIAN_CODENAME} AS php-zts

WORKDIR /srv/app

ARG DEFAULT_PHP_EXTENSIONS
ARG PHP_EXTENSIONS
ARG APT_PACKAGES
ARG COMPOSER_VERSION
ARG NODE_MAJOR
ARG INSTALL_PHP_EXTENSION_URL
ENV INSTALL_PHP_EXTENSION_URL "${INSTALL_PHP_EXTENSION_URL}"
ENV PHP_EXTENSIONS "${DEFAULT_PHP_EXTENSIONS} ${PHP_EXTENSIONS}"
ENV DOCUMENT_ROOT /srv/app/public
ENV SYMFONY_CLI_URL 'https://github.com/symfony-cli/symfony-cli/releases/latest/download/symfony-cli_linux_amd64.tar.gz'
ENV APT_PACKAGES "${APT_PACKAGES}"
ENV COMPOSER_VERSION "${COMPOSER_VERSION}"

# update and install
RUN set -eux ; \
	mkdir /etc/apt/keyrings/ ; \
	apt-get update ; \
	apt-get install -y ca-certificates curl gnupg ; \
	echo 'deb http://deb.debian.org/debian bullseye-backports main contrib non-free' > /etc/apt/sources.list.d/backports.list ; \
	echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" > /etc/apt/sources.list.d/nodesource.list ; \
	(cd /usr/bin && curl -1sLf $SYMFONY_CLI_URL | tar xfz - symfony) ; \
	curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg ; \
	apt-get update -y && apt-get upgrade -y ; \
	apt-get install -y $APT_PACKAGES ; \
	corepack enable ; \
	corepack prepare yarn@stable --activate ; \
	true

# install php extension. see https://github.com/mlocati/docker-php-extension-installer
RUN set -eux ; \
	curl -sSLf -o '/usr/bin/install-php-extensions' $INSTALL_PHP_EXTENSION_URL ; \
	chmod +x '/usr/bin/install-php-extensions' ; \
	install-php-extensions $PHP_EXTENSIONS ; \
	true

# install composer
RUN set -eux ; \
	curl -sSLf -o '/usr/bin/composer' "https://getcomposer.org/download/$COMPOSER_VERSION/composer.phar" ; \
	chmod +x '/usr/bin/composer' ; \
	true

# install parallel
RUN set -eux ; \
	install-php-extensions parallel

# configurations
RUN set -eux ; \
	mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" ; \
	chsh --shell /bin/bash www-data ; \
	chown www-data /var/www ; \
	mkdir -p '/srv/app/var' ; \
	chmod 777 '/srv/app/var' ; \
	true

# cleanup
RUN set -eux ; \
	rm /etc/cron*/*; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false ; \
	rm -rf /var/lib/apt/lists/*; \
	rm -rf /root/.composer/cache/*; \
	rm -rf /root/.cache; \
	true

#
# fpm-dev
#

FROM php-fpm AS php-fpm-dev

ARG INSTALL_PHP_EXTENSION_URL
ENV INSTALL_PHP_EXTENSION_URL "${INSTALL_PHP_EXTENSION_URL}"

RUN set -eux ; \
	install-php-extensions xdebug ; \
	true

# cleanup
RUN set -eux ; \
	rm -f /etc/cron*/*; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false ; \
	rm -rf /var/lib/apt/lists/*; \
	rm -rf /root/.composer/cache/*; \
	rm -rf /root/.cache; \
	true

#
# zts-dev
#

FROM php-zts AS php-zts-dev

ARG INSTALL_PHP_EXTENSION_URL
ENV INSTALL_PHP_EXTENSION_URL "${INSTALL_PHP_EXTENSION_URL}"

RUN set -eux ; \
	install-php-extensions xdebug ; \
	true

# cleanup
RUN set -eux ; \
	rm -f /etc/cron*/*; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false ; \
	rm -rf /var/lib/apt/lists/*; \
	rm -rf /root/.composer/cache/*; \
	rm -rf /root/.cache; \
	true
