# Docker + October CMS

The docker images defined in this repository serve as a starting point for [October CMS](https://octobercms.com) projects. This image is a clone of the [aspendigital/docker-octobercms](https://github.com/aspendigital/docker-octobercms) image with the addition of git supported custom plugins and themes.

Based on [official docker PHP images](https://hub.docker.com/_/php), images include dependencies required by October, Composer and install the [latest release](https://octobercms.com/changelog).

- [Supported Tags](https://github.com/lpshanley/octobercms#supported-tags)
- [Quick Start](https://github.com/lpshanley/octobercms#quick-start)
- [Working with Local Files](https://github.com/lpshanley/octobercms#working-with-local-files)
- [Database Support](https://github.com/lpshanley/octobercms#database-support)
- [Cron](https://github.com/lpshanley/octobercms#cron)
- [Command Line Tasks](https://github.com/lpshanley/octobercms#command-line-tasks)
- [App Environment](https://github.com/lpshanley/octobercms#app-environment)

---

## Supported Tags

- `latest`: [Dockerfile](https://github.com/lpshanley/octobercms/blob/master/Dockerfile)

## Quick Start

To run October CMS using Docker, start a container using the latest image, mapping your local port 80 to the container's port 80:

```shell
$ docker run -p 80:80 --name october lpshanley/octobercms:latest
# `CTRL-C` to stop
$ docker rm october  # Destroys the container
```

> If there is a port conflict, you will receive an error message from the Docker daemon. Try mapping to an open local port (-p 8080:80) or shut down the container or server that is on the desired port.

 - Visit [http://localhost](http://localhost) using your browser.
 - Login to the [backend](http://localhost/backend) with the username `admin` and password `admin`.
 - Hit `CTRL-C` to stop the container. Running a container in the foreground will send log outputs to your terminal.

Run the container in the background by passing the `-d` option:

```shell
$ docker run -p 80:80 --name october -d lpshanley/octobercms:latest
$ docker stop october  # Stops the container. To restart `docker start october`
$ docker rm october  # Destroys the container
```

## Working with Local Files

Using Docker volumes, you can mount local files inside a container.

The container uses the working directory `/var/www/html` for the web server document root. This is where the October CMS codebase resides in the container. You can replace files and folders, or introduce new ones with bind-mounted volumes:

```shell
# Developing a plugin
$ git clone git@github.com:aspendigital/oc-resizer-plugin.git
$ cd oc-resizer-plugin
$ docker run -p 80:80 --rm \
  -v $(pwd):/var/www/html/plugins/aspendigital/resizer \
  aspendigital/octobercms:latest
```

Save yourself some keyboards strokes, utilize [docker-compose](https://docs.docker.com/compose/overview/) by introducing a `docker-compose.yml` file to your project folder:

```yml
# docker-compose.yml
version: '2.2'
services:
  web:
    image: lpshanley/octobercms
    ports:
      - 80:80
    volumes:
      - $PWD:/var/www/html/plugins/aspendigital/resizer
```
With the above example saved in working directory, run:

```shell
$ docker-compose up -d # start services defined in `docker-compose.yml` in the background
$ docker-compose down # stop and destroy
```


## Database Support

#### SQLite

On build, an SQLite database is [created and initialized](https://github.com/aspendigital/docker-octobercms/blob/d3b288b9fe0606e32ac3d6466affd2996394bdca/Dockerfile.template#L54-L57) for the Docker image. With that database, users have immediate access to the backend for testing and developing themes and plugins. However, changes made to the built-in database will be lost once the container is stopped and removed.

When projects require a persistent SQLite database, copy or create a new database to the host which can be used as a bind mount:

```shell
# Create and provision a new SQLite database:
$ touch storage/database.sqlite
$ docker run --rm \
  -v $(pwd)/storage/database.sqlite:/var/www/html/storage/database.sqlite \
  lpshanley/octobercms php artisan october:up

# Now run with the volume mounted to your host
$ docker run -p 80:80 --name october \
 -v $(pwd)/storage/database.sqlite:/var/www/html/storage/database.sqlite \
 lpshanley/octobercms
```

#### MySQL / Postgres

Alternatively, you can host the database using another container:

```yml
#docker-compose.yml
version: '2.2'
services:
  web:
    image: lpshanley/octobercms:latest
    ports:
      - 80:80
    environment:
      - DB_TYPE=mysql
      - DB_HOST=mysql #DB_HOST should match the service name of the database container
      - DB_DATABASE=octobercms
      - DB_USERNAME=root
      - DB_PASSWORD=root

  mysql:
    image: mysql:latest
    ports:
      - 3306:3306
    environment:
      - MYSQL_ROOT_PASSWORD=root
      - MYSQL_DATABASE=octobercms
```
Provision a new database with `october:up`:

```ssh
$ docker-compose up -d
$ docker-compose exec web php artisan october:up
```

## Cron

You can start a cron process by setting the environment variable `ENABLE_CRON` to `true`:

```shell
$ docker run -p 80:80 -e ENABLE_CRON=true lpshanley/octobercms:latest
```

Separate the cron process into it's own container:

```yml
#docker-compose.yml
version: '2.2'
services:
  web:
    image: lpshanley/octobercms:latest
    init: true
    restart: always
    ports:
      - 80:80
    environment:
      - TZ=America/Denver
    volumes:
      - ./.env:/var/www/html/.env
      - ./plugins:/var/www/html/plugins
      - ./storage/app:/var/www/html/storage/app
      - ./storage/logs:/var/www/html/storage/logs
      - ./storage/database.sqlite:/var/www/html/storage/database.sqlite
      - ./themes:/var/www/html/themes

  cron:
    image: lpshanley/octobercms:latest
    init: true
    restart: always
    command: [cron, -f]
    environment:
      - TZ=America/Denver
    volumes_from:
      - web
```

## Command Line Tasks

Run the container in the background and launch an interactive shell (bash) for the container:


```shell
$ docker run -p 80:80 --name containername -d lpshanley/octobercms:latest
$ docker exec -it containername bash
```

Commands can also be run directly, without opening a shell:

```shell
# artisan
$ docker exec containername php artisan env

# composer
$ docker exec containername composer info
```

A few helper scripts have been added to the image:

```shell
# `october` invokes `php artisan october:"$@"`
$ docker exec containername october up

# `artisan` invokes `php artisan "$@"`
$ docker exec containername artisan plugin:install aspendigital.resizer

# `tinker` invokes `php artisan tinker`. Requires `-it` for an interactive shell
$ docker exec -it containername tinker
```
