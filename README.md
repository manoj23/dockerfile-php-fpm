dockerfile-php-fpm
==================

This is a simple php-fpm container.
This container intends to be as small as possible.

## Example of docker run

### Create network
```
docker network create --subnet=172.18.0.0/16 http-php-bridge
```

### Run the Caddy container
```
docker build https://github.com:/manoj23/dockerfile-caddy.git -t caddy
docker run --rm -ti -p 80:80 \
	--net=http-php-bridge \
	--ip 172.18.0.2 \
	--add-host=php-fpm:172.18.0.3 \
	-v /path/to/Caddyfile:/etc/Caddyfile:ro \
	-v /path/to/srv/:/srv/:ro \
	-v /path/to/var/log:/var/log/ \
	--name caddy caddy
```

### Run the php-fpm container
```
docker build https://github.com:/manoj23/dockerfile-php-fpm.git -t php-fpm
docker run --rm -ti \
	--net=http-php-bridge \
	--ip 172.18.0.3 \
	-v /path/to/php-fpm.conf:/etc/php-fpm.conf:ro \
	-v /path/to/srv/:/srv/:ro \
	-v /path/to/var/log:/var/log/ \
	--name php-fpm php-fpm
```

## Configuration files

### Caddyfile
```
http://127.0.0.1:80
gzip
root /srv/
fastcgi / php-fpm:9000 php
log /var/log/access.log {
	rotate_size 100
	rotate_compress
}
errors /var/log/error.log {
	rotate_size 100
	rotate_compress
}
```

### php-fpm.conf
```
[global]
daemonize = no
[www]
user = nobody
group = nobody
listen = 0.0.0.0:9000
pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
access.log = log/$pool.access.log
```

## Example of docker-compose.yml with caddy

Put in a folder:
* Caddy server configuration file: Caddyfile
* php-fpm server configuration file: php-fpm.conf
* PHP page web: index.php
* docker-compose.yml as below
```
version: '3'
services:
  http:
    build: https://github.com:/manoj23/dockerfile-caddy.git
    image: caddy
    volumes:
     - ./Caddyfile:/etc/Caddyfile:ro
     - ./index.php:/srv/index.php:ro
     - ./log/:/var/log
    ports:
     - "80:80"
  php-fpm:
    build: https://github.com:/manoj23/dockerfile-php-fpm.git
    image: php-fpm
    volumes:
     - ./php-fpm.conf:/etc/php-fpm.conf:ro
     - ./index.php:/srv/index.php:ro
     - ./log/:/var/log
```
