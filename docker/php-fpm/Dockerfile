ARG PHP_VERSION=7.4-fpm-alpine3.12
ARG CONSUL_TEMPLATE_VERSION=0.25.0-scratch

#
# BASE IMAGE
#

FROM php:${PHP_VERSION} as php-base
ARG PHPREDIS_VERSION=5.3.1
ARG PHPIZE_DEPS

## Install composer
RUN wget https://getcomposer.org/installer && \
    php installer --install-dir=/usr/local/bin/ --filename=composer && \
    rm installer \
    # Update the index of available packages
    && apk update \
    # Install run dependencies
    && apk add --no-cache freetype libpng libjpeg-turbo libzip libsodium gmp libmcrypt git \
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
    ## Cleanup
    && apk del .build-deps && rm -rf /var/cache/apk/*

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

## Install application dependencies
RUN composer install --no-interaction --optimize-autoloader

## Change files owner to php-fpm default user
RUN chown -R www-data:www-data . \
    && chmod -R 777 /laravel/storage

RUN php -m \
    && php artisan list

#
# DEV IMAGE
#

FROM php-base AS dev

ARG APP_ENV="dev"
ARG PHPIZE_DEPS

ENV APP_ENV=${APP_ENV}
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV COMPOSER_MEMORY_LIMIT=-1

# Install run dependencies
RUN docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
    # Install run dependencies
    && apk add --no-cache --virtual .build-deps $PHPIZE_DEPS \
    # build tools
    autoconf g++ gcc make \
    # lib tools
    bzip2-dev freetype-dev gettext-dev icu-dev imagemagick-dev libintl libjpeg-turbo-dev \
    #  libmcrypt-dev
    libpng-dev libxslt-dev libzip-dev

WORKDIR /laravel
## Copy project files to workdir
COPY . .

## Install application dependencies
RUN composer install --no-interaction --optimize-autoloader

## Install Xdebug
RUN yes | pecl install xdebug
### Copy xdebug configuration for remote debugging
COPY ./docker/php-fpm/xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini
RUN docker-php-ext-enable xdebug

## Copy php default configuration
COPY ./docker/php-fpm/default.ini /usr/local/etc/php/conf.d/
COPY ./docker/php-fpm/pool.conf /usr/local/etc/php-fpm.d/www.conf

## Change files owner to php-fpm default user
RUN chown -R www-data:www-data . \
    && chmod -R 777 /laravel/storage

## Cleanup
RUN apk del .build-deps \
    && rm -rf /var/cache/apk/*

#
# LOCAL IMAGE
#

FROM dev AS local

ARG APP_ENV=local
ARG PHPIZE_DEPS

ENV APP_ENV=${APP_ENV}
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV COMPOSER_MEMORY_LIMIT=-1

#
# PROD IMAGE
#

FROM hashicorp/consul-template:${CONSUL_TEMPLATE_VERSION} as consul-template
FROM php-base AS prod

ARG APP_ENV="prod"
ARG COMMIT
ARG VERSION
ARG VAULT_ADDR

ENV APP_ENV=${APP_ENV}
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
