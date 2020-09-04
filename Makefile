# export variables from .env.testing file to variables
include .env.testing
VARS:=$(shell sed -ne 's/ *\#.*$$//; /./ s/=.*$$// p' .env.testing )
$(foreach v,$(VARS),$(eval $(shell echo export "TEST_$(v)"="$($(v))")))

# export variables from .env file to variables
include .env
VARS:=$(shell sed -ne 's/ *\#.*$$//; /./ s/=.*$$// p' .env )
$(foreach v,$(VARS),$(eval $(shell echo export $(v)="$($(v))")))

LOWER_PROJECT_NAME = `echo $(PROJECT_NAME) | tr A-Z a-z`
TEST_LOWER_PROJECT_NAME = `echo $(TEST_PROJECT_NAME) | tr A-Z a-z`

test:
	@echo PROJECT_NAME is $(PROJECT_NAME)
	@echo APP_ENV is $(APP_ENV)
	@echo "\n"
	@echo TEST_PROJECT_NAME is $(TEST_PROJECT_NAME)
	@echo TEST_APP_ENV is $(TEST_APP_ENV)
	@echo "\n"
	@echo TEST_LOWER_PROJECT_NAME is $(TEST_LOWER_PROJECT_NAME)
	@echo TEST_POSTGRES_PASSWORD is $(TEST_DB_PASSWORD)
	@echo TEST_POSTGRES_USER is $(TEST_DB_USERNAME)
	@echo TEST_POSTGRES_DB is $(TEST_DB_DATABASE)
	@echo "\n"
	@echo ENV
	@printenv
build: ## Build docker containers
	docker-compose up -d --build
up-build-test: ## Setup environment for running tests via github actions
	docker build --target $(TEST_APP_ENV) -t $(TEST_LOWER_PROJECT_NAME)-php:$(TEST_APP_ENV) -f docker/php-fpm/Dockerfile .
	docker build --target $(TEST_APP_ENV) -t $(TEST_LOWER_PROJECT_NAME)-nginx:$(TEST_APP_ENV) -f docker/nginx/Dockerfile .
	docker build --target $(TEST_APP_ENV) -t $(TEST_LOWER_PROJECT_NAME)-postgres:$(TEST_APP_ENV) -f docker/postgres/Dockerfile .
	docker network create $(TEST_LOWER_PROJECT_NAME)-network
	docker run --rm --network $(TEST_LOWER_PROJECT_NAME)-network --detach --name php-fpm $(TEST_LOWER_PROJECT_NAME)-php:$(TEST_APP_ENV)
	docker run --rm --network $(TEST_LOWER_PROJECT_NAME)-network --detach --publish 80:80 $(TEST_LOWER_PROJECT_NAME)-nginx:$(TEST_APP_ENV)
	docker run --rm --network $(TEST_LOWER_PROJECT_NAME)-network --detach --name pgsql -e POSTGRES_PASSWORD=$(TEST_DB_PASSWORD) -e PGPASSWORD=$(TEST_DB_PASSWORD) -e POSTGRES_USER=$(TEST_DB_USERNAME) -e POSTGRES_DB=$(TEST_DB_DATABASE) --publish 5432:5432 $(TEST_LOWER_PROJECT_NAME)-postgres:$(TEST_APP_ENV)
	docker run --rm --network $(TEST_LOWER_PROJECT_NAME)-network $(TEST_LOWER_PROJECT_NAME)-php:$(TEST_APP_ENV) sh -c "cp .env.testing .env"
	docker run --rm --network $(TEST_LOWER_PROJECT_NAME)-network $(TEST_LOWER_PROJECT_NAME)-php:$(TEST_APP_ENV) sh -c "php artisan key:generate -n"
	docker run --rm --network $(TEST_LOWER_PROJECT_NAME)-network $(TEST_LOWER_PROJECT_NAME)-php:$(TEST_APP_ENV) sh -c "php artisan jwt:secret"
	docker run --rm --network $(TEST_LOWER_PROJECT_NAME)-network $(TEST_LOWER_PROJECT_NAME)-php:$(TEST_APP_ENV) sh -c "php artisan storage:link"
	docker run --rm --network $(TEST_LOWER_PROJECT_NAME)-network $(TEST_LOWER_PROJECT_NAME)-php:$(TEST_APP_ENV) sh -c "php artisan migrate"
	docker run --rm --network $(TEST_LOWER_PROJECT_NAME)-network $(TEST_LOWER_PROJECT_NAME)-php:$(TEST_APP_ENV) sh -c "php artisan test"
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
