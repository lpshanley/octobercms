FROM php:7.1-apache

RUN apt-get update && apt-get install -y cron git-core jq vim \
  libjpeg-dev libpng-dev libpq-dev libsqlite3-dev && \
  rm -rf /var/lib/apt/lists/* && \
  docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr && \
  docker-php-ext-install gd mysqli opcache pdo_pgsql pdo_mysql zip

RUN { \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=2'; \
    echo 'opcache.fast_shutdown=1'; \
    echo 'opcache.enable_cli=1'; \
  } > /usr/local/etc/php/conf.d/docker-oc-opcache.ini

RUN { \
    echo 'log_errors=on'; \
    echo 'display_errors=off'; \
    echo 'upload_max_filesize=32M'; \
    echo 'post_max_size=32M'; \
    echo 'memory_limit=128M'; \
  } > /usr/local/etc/php/conf.d/docker-oc-php.ini

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
  /usr/local/bin/composer global require hirak/prestissimo

ENV COMPOSER_ALLOW_SUPERUSER=1

RUN a2enmod rewrite

COPY config/docker /usr/src/octobercms-config-docker

ENV OCTOBERCMS_TAG v1.0.443
ENV OCTOBERCMS_CHECKSUM df3e9c5ded19ecbcc8aa07aff3a4c65dc8cc537f
ENV OCTOBERCMS_CORE_BUILD 443
ENV OCTOBERCMS_CORE_HASH 8dccb2043759b385e46cc3cf6a36c4b4

RUN git clone https://github.com/octobercms/october.git -b $OCTOBERCMS_TAG --depth 1 . && \
  composer install --no-interaction --prefer-dist --no-scripts && \
  composer clearcache && \
  git status && git reset --hard HEAD && \
  rm -rf .git && \
  echo 'APP_ENV=docker' > .env && \
  mv /usr/src/octobercms-config-docker config/docker && \
  touch storage/database.sqlite && \
  chmod 666 storage/database.sqlite && \
  php artisan october:up && \
  php artisan plugin:install october.drivers && \
  php artisan plugin:install RainLab.User && \
  php artisan plugin:install Vdomah.JWTAuth && \
  chown -R www-data:www-data /var/www/html && \
  find . -type d \( -path './plugins' -or  -path './storage' -or  -path './themes' -or  -path './plugins/*' -or  -path './storage/*' -or  -path './themes/*' \) -exec chmod g+rwxs {} \;

RUN cp ./plugins/vdomah/jwtauth/config/auth.php ./config/auth.php
  
RUN php -r "use System\\Models\\Parameter; \
    require __DIR__.'/bootstrap/autoload.php'; \
    \$app = require_once __DIR__.'/bootstrap/app.php'; \
    \$app->make('Illuminate\\Contracts\\Console\\Kernel')->bootstrap(); \
    Parameter::set(['system::core.build'=>getenv('OCTOBERCMS_CORE_BUILD'), 'system::core.hash'=>getenv('OCTOBERCMS_CORE_HASH')]); \
    echo \"October CMS \\n Build: \",Parameter::get('system::core.build'), \"\\n Hash: \", Parameter::get('system::core.hash'), \"\\n\";"

RUN echo "* * * * * /usr/local/bin/php /var/www/html/artisan schedule:run > /proc/1/fd/1 2>/proc/1/fd/2" > /etc/cron.d/october-cron && \
  crontab /etc/cron.d/october-cron

RUN echo 'exec php artisan "$@"' > /usr/local/bin/artisan && \
  echo 'exec php artisan tinker' > /usr/local/bin/tinker && \
  echo '[ $# -eq 0 ] && exec php artisan october || exec php artisan october:"$@"' > /usr/local/bin/october && \
  sed -i '1s;^;#!/bin/bash\n[ "$PWD" != "/var/www/html" ] \&\& echo " - Helper must be run from /var/www/html" \&\& exit 1\n;' /usr/local/bin/artisan /usr/local/bin/tinker /usr/local/bin/october && \
  chmod +x /usr/local/bin/artisan /usr/local/bin/tinker /usr/local/bin/october

COPY ./docker-entrypoint /usr/local/bin/

RUN chmod 755 /usr/local/bin/docker-entrypoint

ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]

RUN find ./var/www/html/themes
RUN find ./var/www/html/plugins

CMD ["apache2-foreground"]