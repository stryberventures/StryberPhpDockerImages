ARG PHP_VERSION=8.0-fpm-alpine
ARG CONSUL_TEMPLATE_VERSION=0.25.0-scratch

#
# BASE IMAGE
#

FROM php:${PHP_VERSION} as php-base
ARG PHPREDIS_VERSION=5.3.2

## Install composer
RUN apk update \
    # Install run dependencies
    && apk add --no-cache freetype libpng libjpeg-turbo libzip libsodium gmp libmcrypt git openssh \
    # Install build packages
    && apk add --no-cache --virtual .build-deps $PHPIZE_DEPS freetype-dev libpng-dev libjpeg-turbo-dev zlib-dev libzip-dev \
       libxml2-dev libsodium-dev gmp-dev libmcrypt-dev \
    && apk add postgresql-dev \
    # Install redis
    && mkdir -p /usr/src/php/ext/ \
    && curl -L -o /tmp/phpredis.tar.gz https://github.com/phpredis/phpredis/archive/${PHPREDIS_VERSION}.tar.gz \
    && tar xfz /tmp/phpredis.tar.gz \
    && rm -r /tmp/phpredis.tar.gz \
    && mv phpredis-${PHPREDIS_VERSION} /usr/src/php/ext/redis \
    # Configure and install gd
    && NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) \
    && docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ \
    && docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
    && docker-php-ext-install -j${NPROC} gd \
    && php -r 'var_dump(gd_info());' \
    # Install Postgre PDO
    && docker-php-ext-install -j${NPROC} pdo pdo_pgsql pgsql \
    # Install php extensions
    && docker-php-ext-install -j${NPROC} zip soap intl bcmath sodium gmp redis pcntl \
    && docker-php-ext-enable redis pcntl \
    # Enable production php.ini
    && mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" \
    ## Cleanup
    && apk del .build-deps && rm -rf /var/cache/apk/*

##
## DEV IMAGE
##
#
FROM php-base AS dev

ARG XDEBUG_VERSION=3.0.1

# Install run dependencies
RUN docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
    # Install run dependencies
    && apk add --no-cache --virtual .build-deps $PHPIZE_DEPS \
    # lib tools
    bzip2-dev freetype-dev gettext-dev icu-dev imagemagick-dev libintl libjpeg-turbo-dev \
    #  libmcrypt-dev
    libpng-dev libxslt-dev libzip-dev \
    # Enable development php.ini
    && mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

## Copy php default configuration
COPY ./config/default.ini /usr/local/etc/php/conf.d/
COPY ./config/pool.conf /usr/local/etc/php-fpm.d/www.conf
## Copy php default configuration
COPY ./config/xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini

# Install Xdebug
RUN yes | pecl install xdebug-${XDEBUG_VERSION} \
    && docker-php-ext-enable xdebug

## Cleanup
RUN apk del .build-deps \
    && rm -rf /var/cache/apk/*

