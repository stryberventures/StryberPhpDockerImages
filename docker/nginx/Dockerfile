ARG NGINX_VERSION=1.19

# Dev image
FROM nginx:${NGINX_VERSION}-alpine as dev

# Copy nginx config
COPY ./docker/nginx/nginx.conf /etc/nginx/

# Prod image
FROM dev as testing

# Prod image
FROM dev as prod
