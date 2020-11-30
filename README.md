# PHP-based Stryber Docker images
This repository is used to standardize Docker containers within PHP-based Stryber projects.

# :exclamation: To view the repository code, go to the desired php branch(php-7.4, php-8.0, etc...) 

## PHP Docker image
A Docker image based on the official PHP alpine images with PHP extensions and tools installed to be ready to run laravel web servers.

#### PHP Extensions
 - `pdo`
 - `pdo_pgsql`
 - `pgsql`
 - `soap` 
 - `intl` 
 - `bcmath` 
 - `sodium` 
 - `gmp` 
 - `redis` 
 - `pcntl`

## Automatic builds
Docker images are [building](https://github.com/orgs/stryberventures/packages) automatically 
after committing to the ```php-${VERSION}``` branch with the label ```latest```.

## Usage
First you need to create [personal access token](https://github.com/settings/tokens) with **read:packages** access.
Then you need to [authenticate with a personal access token](https://docs.github.com/en/packages/using-github-packages-with-your-projects-ecosystem/configuring-docker-for-use-with-github-packages#authenticating-with-a-personal-access-token).

Example:
```echo 46941ddda01faaf4f4ee3aa491b3vbnm10518gv4 | docker login https://docker.pkg.github.com -u stryber --password-stdin```

To use this docker images in your project, simply start your ```Docker``` file with importing an image from the chosen package,
for example:
```FROM docker.pkg.github.com/stryberventures/stryberphpdockerimages/stryber-php-7.4:latest```


## Multistage builds
You can find examples of [stages](https://docs.docker.com/develop/develop-images/multistage-build/) for different 
environments(test, dev, prod) inside ```docker/php-fpm/Dockerfile``` file.

To build an image for a specific environment use a command like
```docker build --target ${STAGE} -t ${TAG} -f docker/php-fpm/Dockerfile .```.

In case you are using a ```docker-compose.yml``` file, pass ```target``` with the desired stage.
```
php-fpm:
  build:
    ...
    dockerfile: ./docker/php-fpm/Dockerfile
    target: ${APP_ENV}
```

# Local development
## Main stack
- [x] PHP-FPM with Xdebug
- [x] Nginx
- [x] Redis
- [x] Postgres
- [ ] MySql

## Tools
- [x] Maildev
- [x] phpRedisAdmin
- [ ] Supervisor
- [ ] Yours suggestions :heart_eyes:

---

## Configuration
Copy ```./docker``` folder to your project.

Copy/adapt content from ```.env``` and ```.env.testing```(for testing environment) files to your project.

Copy/adapt content from ```docker-compose.yml``` and ```docker-compose.override.yml``` files to your project.


### PHP-FPM
 - To modify default php settings like ```memory_limit``` edit ```docker/php-fpm/default.ini``` file.
 - To modify php-fpm pool of processes settings edit ```docker/php-fpm/pool.conf``` file.
 - To modify Xdebug settings edit ```docker/php-fpm/xdebug.ini``` file.
 
Don't forget to restart container after editing configuration files :eyes:.

### Nginx
 - To modify nginx settings for ```localhost``` edit ```docker/nginx/conf.d/default.conf``` file.
 - To modify nginx settings for ```*.local.gd``` edit ```docker/nginx/sites-available/local.gd.conf``` file.
local.gd - service to serve localhost. DNS that always resolves to 127.0.0.1.
 - To modify main nginx settings edit ```docker/nginx/nginx.conf```

Don't forget to restart container after editing ```docker/nginx/nginx.conf``` configuration file :eyes:.

### Redis
Just ready to run without settings.

### Postgres
For local development, database user, password, and name are taken from environment variables ```.env``` file(or system environment variables)

If you want to create another database/make some actions on DB, you can use ```docker/postgres/conf/createdb.sh``` file.

### MySql
Do we need this ?

---

### Maildev
MailDev is a simple way to test your project's generated emails during development with an easy to use web interface
![Maildev screenshot](https://raw.githubusercontent.com/maildev/maildev/gh-pages/images/screenshot-2015-03-29.png)


### phpRedisAdmin
phpRedisAdmin is a simple web interface to manage Redis databases

# Running tests via github actions flow
Create ```.github/workflows/main.yml``` file with given content.
```
name: CI
on: [ pull_request ]
jobs:
  test:
    name: Run tests
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v2

      - name: Login to github registry
        run: echo ${{ secrets.GITHUB_TOKEN }} | docker login https://docker.pkg.github.com -u ${{ github.actor }} --password-stdin

      - name: Copy env
        working-directory: .
        run: cp .env.testing .env

      - name: Run make up-build-test
        run: make up-build-test

```

Copy/adapt content from ```Makefile``` file to your project.
