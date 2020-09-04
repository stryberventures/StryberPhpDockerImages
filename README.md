# Docker images 
for local development based on **production** images

## Main stack
- [x] PHP-FPM (uses for dev, testing and production environments)
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
...

### Postgres
...

### MySql
Do we need this ?

---

### Maildev
MailDev is a simple way to test your project's generated emails during development with an easy to use web interface
![Maildev screenshot](https://raw.githubusercontent.com/maildev/maildev/gh-pages/images/screenshot-2015-03-29.png)


### phpRedisAdmin
...

### Supervisor
...

# Pushing new images to GitHub registry
~/github_token.txt - file with [personal access token](https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token)


```
cat ~/github_token.txt | docker login https://docker.pkg.github.com -u USER --password-stdin
docker build --target php-base -t stryber-php:0.0.1 -f docker/php-fpm/Dockerfile .
docker tag b7bbe48b5a01 docker.pkg.github.com/stryberventures/stryberphpdockerimages/stryber-php:0.0.1
docker build --target php-base -t docker.pkg.github.com/stryberventures/stryberphpdockerimages/stryber-php:0.0.1 YOUR_PATH/docker/php-fpm
docker push docker.pkg.github.com/stryberventures/stryberphpdockerimages/stryber-php:0.0.1
```
