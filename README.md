# Docker + October CMS

The docker images defined in this repository serve as a starting point for [October CMS](https://octobercms.com) projects. This image is a clone of the [aspendigital/docker-octobercms](https://github.com/aspendigital/docker-octobercms) image with the addition of git supported custom plugins and themes.

Based on [official docker PHP images](https://hub.docker.com/_/php), images include dependencies required by October, Composer and install the [latest release](https://octobercms.com/changelog).

- [Supported Tags](https://github.com/lpshanley/octobercms#supported-tags)
- [Quick Start](https://github.com/lpshanley/octobercms#quick-start)
- [Working with Local Files](https://github.com/lpshanley/octobercms#working-with-local-files)
- [October Themes and Plugins](https://github.com/lpshanley/octobercms#october-themes-and-plugins)
- [Git Themes and Plugins](https://github.com/lpshanley/octobercms#git-themes-and-plugins)
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
  lpshanley/octobercms:latest
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

## October Themes and Plugins
Themes and/or plugins can be installed from the marketplace with the following environment variables:
* `-e OCTOBER_THEMES=...` (defaults to null)
* `-e OCTOBER_PLUGINS=...` (defaults to null)

Use semicolon separated list for multiple themes or plugins (e.g. `-e OCTOBER_PLUGINS="RainLab.Blog;RainLab.GoogleAnalytics"`)

## Git Themes and Plugins
Themes and/or plugins can be installed from the git repositories with the following environment variables:
* `-e GIT_HOSTS=...` (defaults to null, used to add git servers to /root/.ssh/known_hosts, only needed for ssh)
* `-e GIT_THEMES=...` (defaults to null)
* `-e GIT_PLUGINS=...` (defaults to null)

Use semicolon separated list for multiple themes or plugins (e.g. `-e GIT_THEMES="git@gitlab.com:path/repo.git"`)

If you use a private repository, then you should map your private key to the container (e.g `-v ~/.ssh/id_rsa:/root/.ssh/id_rsa`)

Another solution is to get an "Personal Access Token" from your repository provider and use https instead (e.g. `-e GIT_THEMES="https://username:token@gitlab.com:path/repo.git"`)

Please note that for Plugins, it will determine namespace based on your repository path (e.g `git@gitlab.com:mycompany/blog.git` will clone into `/plugins/mycompany/blog`)

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

## Storage

Storage will require the October.Drivers; plugin which is installed in this image by default. Example below is for amazon s3 storage however rackspace env details are also available below.

#### Amazon S3
```yml
#docker-compose.yml
version: '2.2'
services:
  web:
    image: lpshanley/octobercms:latest
    ports:
      - 80:80
    environment:
      - FS_DEFAULT=s3
      - FS_S3_KEY=amazonprovisionedkey
      - FS_S3_SECRET=amazonprovisionedsecret
      - FS_S3_REGION=us-east-2
      - FS_S3_BUCKET=example-bucket
      - FS_UPLOAD_PATH=https://us-east-2.amazonaws.com/example-bucket/uploads
      - FS_MEDIA_PATH=https://us-east-2.amazonaws.com/example-bucket/media
```
Rackspace ENV details are available below.

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

## App Environment

By default, `APP_ENV` is set to `docker`.

On image build, a default `.env` is [created](https://github.com/aspendigital/docker-octobercms/blob/d3b288b9fe0606e32ac3d6466affd2996394bdca/Dockerfile.template#L52) and [config files](https://github.com/aspendigital/docker-octobercms/tree/master/config/docker) for the `docker` app environment are copied to `/var/www/html/config/docker`. Environment variables can be used to override the included default settings via [`docker run`](https://docs.docker.com/engine/reference/run/#env-environment-variables) or [`docker-compose`](https://docs.docker.com/compose/environment-variables/).

> __Note__: October CMS settings stored in a site's database override the config. Active theme, mail configuration, and other settings which are saved in the database will ultimately override configuration values.

#### PHP configuration

Recommended [settings for opcache and PHP are applied on image build](https://github.com/aspendigital/docker-octobercms/blob/f3c545fd84e293a67e63f86bf94f2bf2ab22ca15/Dockerfile.template#L9-L25).

Values set in `docker-oc-php.ini` can be overridden by passing one of the supported PHP environment variables defined below.

To customize the PHP configuration further, add or replace `.ini` files found in `/usr/local/etc/php/conf.d/`.

### Environment Variables


Environment variables can be passed to both docker-compose and October CMS.

 > Database credentials and other sensitive information should not be committed to the repository. Those required settings should be outlined in __.env.example__

 > Passing environment variables via Docker can be problematic in production. A `phpinfo()` call may leak secrets by outputting environment variables.  Consider mounting a `.env` volume or copying it to the container directly.


#### Docker Entrypoint

The following variables trigger actions run by the [entrypoint script](https://github.com/lpshanley/octobercms/blob/master/docker-oc-entrypoint) at runtime.

| Variable | Default | Action |
| -------- | ------- | ------ |
| ENABLE_CRON | false | `true` starts a cron process within the container |
| FWD_REMOTE_IP | false | `true` enables remote IP forwarding from proxy (Apache) |
| GIT_CHECKOUT |  | Checkout branch, tag, commit within the container. Runs `git checkout $GIT_CHECKOUT` |
| GIT_MERGE_PR |  | Pass GitHub pull request number to merge PR within the container for testing |
| OCTOBER_THEMES | null | List of offical october themes to install on build |
| OCTOBER_PLUGINS | null | List of official october plugins to install on build |
| GIT_HOSTS | null | used to add git servers to /root/.ssh/known_hosts, only needed for ssh |
| GIT_THEMES | null | ex `https://github.com/<user>/<repo>.git` pulls theme repository from git into the project |
| GIT_PLUGINS | null | ex `https://github.com/<user>/<repo>.git` pulls plugin repository from git into the project |
| INIT_PLUGINS | false | `true` runs composer install in plugins folders where no 'vendor' folder exists. `force` runs composer install regardless. Helpful when using git submodules for plugins. |
| PHP_DISPLAY_ERRORS | off | Override value for `display_errors` in docker-oc-php.ini |
| PHP_POST_MAX_SIZE | 32M | Override value for `post_max_size` in docker-oc-php.ini |
| PHP_MEMORY_LIMIT | 128M | Override value for `memory_limit` in docker-oc-php.ini |
| PHP_UPLOAD_MAX_FILESIZE | 32M | Override value for `upload_max_filesize` in docker-oc-php.ini |
| UNIT_TEST |  | `true` runs all October CMS unit tests. Pass test filename to run a specific test. |
| VERSION_INFO | false | `true` outputs container current commit, php version, and dependency info on start |

#### October CMS app environment config

List of variables used in `config/docker`

| Variable | Default |
| -------- | ------- |
| APP_DEBUG | false |
| APP_URL | http://localhost |
| APP_KEY | 0123456789ABCDEFGHIJKLMNOPQRSTUV |
| CACHE_STORE | file |
| CMS_ACTIVE_THEME | demo |
| CMS_EDGE_UPDATES | false  (true in `edge` images) |
| CMS_DISABLE_CORE_UPDATES | true |
| CMS_BACKEND_SKIN | Backend\Skins\Standard |
| CMS_LINK_POLICY | detect |
| CMS_BACKEND_FORCE_SECURE | false |
| DB_TYPE | sqlite |
| DB_SQLITE_PATH | storage/database.sqlite |
| DB_HOST | mysql* |
| DB_PORT | - |
| DB_DATABASE | - |
| DB_USERNAME | - |
| DB_PASSWORD | - |
| DB_REDIS_HOST | redis* |
| DB_REDIS_PASSWORD | null |
| DB_REDIS_PORT | 6379 |
| FS_CLOUD | s3 |
| FS_DEFAULT | local |
| FS_PATH_UPLOAD | /storage/app/uploads |
| FS_PATH_MEDIA | /storage/app/media |
| FS_S3_BUCKET | your-bucket |
| FS_S3_KEY | your-key |
| FS_S3_REGION | your-region |
| FS_S3_SECRET | your-secret |
| FS_RS_CONTAINER | your-container |
| FS_RS_ENDPOINT | https://identity.api.rackspacecloud.com/v2.0/ |
| FS_RS_KEY | your-key |
| FS_RS_REGION | IAD |
| FS_RS_USERNAME | your-username |
| MAIL_DRIVER | log |
| MAIL_SMTP_HOST | - |
| MAIL_SMTP_PORT | 587 |
| MAIL_FROM_ADDRESS | no-reply@domain.tld |
| MAIL_FROM_NAME | October CMS |
| MAIL_SMTP_ENCRYPTION | tls |
| MAIL_SMTP_USERNAME | - |
| MAIL_SMTP_PASSWORD | - |
| OCTOBER_CMS_BACKEND_URI | 'backend' |
| QUEUE_DRIVER | sync |
| SESSION_DRIVER | file |
| TZ\** | UTC |

<small>\* When using a container to serve a database, set the host value to the service name defined in your docker-compose.yml</small>

<small>\** Timezone applies to both container and October CMS  config</small>