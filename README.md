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
...

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
