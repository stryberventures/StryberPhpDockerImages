# Dev image
ARG POSTGRES_VERSION=alpine
FROM postgres:${POSTGRES_VERSION} as dev

CMD ["postgres"]

EXPOSE 5432

# Test image
FROM dev as testing

# Prod image
FROM dev as prod
