ARG PHP_VERSION=8.0-fpm-alpine
ARG CONSUL_TEMPLATE_VERSION=0.25.0-scratch

#
# BASE IMAGE
#

FROM php:${PHP_VERSION} as php-base
ARG PHPREDIS_VERSION=5.3.2

# Update the index of available packages
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
    && docker-php-ext-install -j${NPROC} gd \
    && php -r 'var_dump(gd_info());' \
    # Install Postgre PDO
    && docker-php-ext-install -j${NPROC} pdo pdo_pgsql pgsql \
    # Install php extensions
    && docker-php-ext-install -j${NPROC} zip soap intl bcmath sodium gmp redis pcntl \
    && docker-php-ext-enable redis pcntl \
    # Install mongodb
    && pecl install mongodb && docker-php-ext-enable mongodb \
    # Enable production php.ini
    && mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" \
    ## Cleanup
    && apk del .build-deps && rm -rf /var/cache/apk/*

#
# DEV IMAGE
#

FROM php-base AS dev

ARG APP_ENV="dev"
ARG XDEBUG_VERSION=3.0.2

ENV APP_ENV=${APP_ENV}
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV COMPOSER_MEMORY_LIMIT=-1

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
COPY ./docker/php-fpm/default.ini /usr/local/etc/php/conf.d/
COPY ./docker/php-fpm/pool.conf /usr/local/etc/php-fpm.d/www.conf
## Copy php default configuration
COPY ./docker/php-fpm/xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini

# Install Xdebug
RUN set -ex && mkdir -p /usr/src/php/ext/xdebug \
    && curl -fsSL https://pecl.php.net/get/xdebug-${XDEBUG_VERSION} | tar xvz -C "/usr/src/php/ext/xdebug" --strip 1 \
    && docker-php-ext-install xdebug

WORKDIR /laravel
## Copy project files to workdir
COPY . .

## Cleanup
RUN apk del .build-deps \
    && rm -rf /var/cache/apk/*

#
# TEST IMAGE
#

FROM php-base AS test

ARG APP_ENV="test"

ENV APP_ENV=${APP_ENV}
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV COMPOSER_MEMORY_LIMIT=-1

RUN docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql

WORKDIR /laravel
## Copy project files to workdir
COPY . .

## Change files owner to php-fpm default user
RUN chown -R www-data:www-data . \
    && chmod -R 777 /laravel/storage

RUN php -m \
    && php artisan listlaravel/storage

#
# LOCAL IMAGE
#

FROM dev AS local

ARG APP_ENV=local

ENV APP_ENV=${APP_ENV}
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV COMPOSER_MEMORY_LIMIT=-1

#
# PROD IMAGE
#

FROM hashicorp/consul-template:${CONSUL_TEMPLATE_VERSION} as consul-template

ARG COMPOSER=2.0.9
FROM composer:${COMPOSER} as composer
WORKDIR /composer

FROM php-base AS prod

ARG COMMIT
ARG VERSION
ARG VAULT_ADDR

ENV VAULT_ADDR=${VAULT_ADDR}
ENV COMPOSER_MEMORY_LIMIT=-1

RUN docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql

COPY --from=consul-template /consul-template /usr/local/bin/
COPY docker/php-fpm/consul-template.hcl /etc/consul-template/consul-template.hcl

WORKDIR /laravel

COPY app/ app/
COPY bootstrap/ bootstrap/
COPY config/ config/
COPY database/ database/
COPY public/ public/
COPY resources/ resources/
COPY routes/ routes/
COPY storage/ storage/
COPY artisan .
COPY composer.json .

RUN composer install \
    --ignore-platform-reqs \
    --optimize-autoloader \
    --no-interaction \
    --no-plugins \
    --no-scripts \
    --prefer-dist \
    --verbose \
    --no-dev \
    && composer show --tree|grep "ext-" || true

RUN if [ -n "${COMMIT}" ]; then \
      printf '%s' "${COMMIT}" > "COMMIT"; \
      echo "COMMIT: $(cat COMMIT)"; \
    fi

RUN if [ -n "${VERSION}" ]; then \
      printf '%s' "${VERSION}" > "VERSION"; \
      echo "VERSION: $(cat VERSION)"; \
    fi

RUN if [ -n "${VAULT_ADDR}" ]; then \
      echo "${VAULT_ADDR}" \
        && curl --insecure "${VAULT_ADDR}/v1/pki/ca_chain" \
          -o "/usr/local/share/ca-certificates/ca-cert-int-chain.crt" \
        && update-ca-certificates; \
    fi

RUN php artisan cache:clear \
    && php artisan route:clear \
    && php artisan config:clear \
    && php -m \
    && php artisan list

CMD if [ -n "${VAULT_ADDR}" ]; then \
      echo "${VAULT_ADDR}" \
        && consul-template \
          -vault-addr="${VAULT_ADDR}" \
          -config="/etc/consul-template/consul-template.hcl"; \
    else \
      php-fpm; \
    fi
