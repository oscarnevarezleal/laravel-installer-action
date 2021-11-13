FROM amazonlinux:2
ARG INSTALL_RECOMMENDED=1
MAINTAINER "Oscar Nevarez" <fu.wire@gmail.com>

# |--------------------------------------------------------------------------
# | NodeJs Details
# |--------------------------------------------------------------------------
ARG NODE_VERSION=12.14.1
ENV NVM_DIR /usr/local/nvm

# |--------------------------------------------------------------------------
# | Default PHP extensions to be enabled
# | By default, enable all the extensions that are enabled on a base Ubuntu install
# |--------------------------------------------------------------------------
ARG PHP_EXTENSIONS="cgi,curl,mbstring,gd,mysqlnd,gettext,json,xml,fpm,intl,zip"
ENV PHP_VERSION=7.4
ARG GROUP_ID=1001
ARG USER_ID=1001

RUN yum update -y \
    && yum install -y yum-utils shadow-utils amazon-linux-extras \
    && amazon-linux-extras enable php${PHP_VERSION} \
    && yum install -y which git jq zip unzip tar wget  \
    && yum install -y yum install php php-common php-pear \
    && yum install -y php-{cgi,curl,mbstring,gd,mysqlnd,gettext,json,xml,fpm,intl,zip} \
    && mkdir -p $NVM_DIR \
    && curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash

RUN useradd -u $USER_ID docker
RUN groupmod -g $GROUP_ID docker

WORKDIR /usr/app

RUN mkdir -p /usr/app/dist \
	&& mkdir -p /usr/app/mount \
    && chown -R docker:$GROUP_ID /usr/app

ADD entrypoint /usr/local/bin/docker-entrypoint
RUN chmod -R ugo+rx /usr/local/bin/docker-entrypoint

# install node and npm
RUN source $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default \
    && node -v \
    npm -v

# add node and npm to path so the commands are available
ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    php -r "if (hash_file('sha384', 'composer-setup.php') === '906a84df04cea2aa72f40b5f787e49f22d4c2f19492ac310e8cba5b96ac8b64115ac402c8cd292b8a03482574915d1a8') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
    php composer-setup.php
    php -r "unlink('composer-setup.php');" && \
    mv composer.phar /usr/local/bin/composer

USER docker

RUN composer global require laravel/installer \
    && chmod ugo+rx ~/.config/composer/vendor/bin/laravel

ENV PATH "~/.config/composer/vendor/bin:~/.composer/vendor/bin:/usr/local/bin:$PATH"

WORKDIR /usr/app
VOLUME /usr/app/dist

ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]
CMD ["laravel", "--version"]