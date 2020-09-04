ARG PHP_VERSION=7.4.8-fpm-alpine3.12
ARG CONSUL_TEMPLATE_VERSION=0.25.0-scratch

# ======== Consul Template ========
FROM hashicorp/consul-template:${CONSUL_TEMPLATE_VERSION} as consul-template

# ======== PHP BASE IMAGE ========
FROM php:${PHP_VERSION} as php-base
ARG PHPREDIS_VERSION=5.3.1

## Install composer
RUN wget https://getcomposer.org/installer && \
    php installer --install-dir=/usr/local/bin/ --filename=composer && \
    rm installer

# Install temporary packages
RUN apk add --no-cache --virtual .build-deps freetype-dev libpng-dev libjpeg-turbo-dev \
 zlib-dev libzip-dev libxml2-dev libsodium-dev gmp-dev libmcrypt-dev git autoconf gcc g++ make

# Install system dependencies
RUN apk add --no-cache freetype libpng libjpeg-turbo libzip postgresql-dev libsodium gmp libmcrypt curl

# Configure gd
RUN docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/

RUN echo ${PHPREDIS_VERSION}

# Install redis
RUN curl -L -o /tmp/phpredis.tar.gz https://github.com/phpredis/phpredis/archive/${PHPREDIS_VERSION}.tar.gz \
    && tar xfz /tmp/phpredis.tar.gz \
    && rm -r /tmp/phpredis.tar.gz \
    && mv phpredis-${PHPREDIS_VERSION} /usr/src/php/ext/redis

# Install php extensions
RUN NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) \
    && docker-php-ext-install -j${NPROC} gd pdo_pgsql pgsql zip soap intl bcmath sodium gmp redis pcntl \
    && docker-php-ext-enable redis pcntl

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

# ======== Dev image ========
FROM php-base AS dev

ENV APP_ENV=dev
WORKDIR /laravel

## Copy project files to workdir
COPY . .

## Install composer plugin that downloads packages in parallel to speed up the installation process.
RUN composer global require hirak/prestissimo

## Install application dependencies
ENV COMPOSER_ALLOW_SUPERUSER=1
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
RUN chown -R www-data:www-data .
RUN chmod -R 777 /laravel/storage

## Cleanup
RUN apk del .build-deps

# ======== Test image ========
FROM php-base AS testing
ENV APP_ENV=testing
WORKDIR /laravel

## Copy project files to workdir
COPY . .

## Install application dependencies
ENV COMPOSER_ALLOW_SUPERUSER=1
RUN composer install --no-interaction --optimize-autoloader

## Change files owner to php-fpm default user
RUN chown -R www-data:www-data .
RUN chmod -R 777 /laravel/storage

RUN php -m && php artisan list

## Cleanup
RUN apk del .build-deps
# ======== Prod image ========
FROM php-base AS prod
ARG COMMIT
ARG VERSION
ARG VAULT_ADDR

ENV APP_ENV=prod
ENV VAULT_ADDR=${VAULT_ADDR}

WORKDIR /laravel

RUN composer install \
      --ignore-platform-reqs \
      --optimize-autoloader \
      --no-interaction \
      --no-plugins \
      --no-scripts \
      --prefer-dist \
      --verbose \
      --no-dev \
    && composer show --tree|grep "ext-"|| true

COPY --from=consul-template /consul-template /usr/local/bin/

COPY docker/php-fpm/consul-template.hcl /etc/consul-template/consul-template.hcl

RUN if [ -n "${COMMIT}" ]; then \
      printf '%s' "${COMMIT}" > "COMMIT"; \
      echo "COMMIT: $(cat COMMIT)"; \
    fi

RUN if [ -n "${VERSION}" ]; then \
      printf '%s' "${VERSION}" > "VERSION"; \
      echo "VERSION: $(cat VERSION)"; \
    fi

RUN php artisan cache:clear \
    && php artisan route:clear \
    && php artisan config:clear

RUN php -m \
    && php artisan list

RUN if [ -n "${VAULT_ADDR}" ]; then \
      echo "${VAULT_ADDR}" \
        && curl --insecure "${VAULT_ADDR}/v1/pki/ca_chain" \
          -o "/usr/local/share/ca-certificates/ca-cert-int-chain.crt" \
        && update-ca-certificates; \
    fi

CMD if [ -n "${VAULT_ADDR}" ]; then \
      echo "${VAULT_ADDR}" \
        && consul-template \
          -vault-addr="${VAULT_ADDR}" \
          -config="/etc/consul-template/consul-template.hcl"; \
    else \
      php-fpm; \
    fi

## Cleanup
RUN apk del .build-deps
