FROM php:5.6.30-apache

MAINTAINER MERHYLSTUDIO <maghin@merhylstudio.fr>

#=== Configure apache ===
RUN { \
    echo '<VirtualHost *:80>'; \
    echo 'ServerName phpmyfaq'; \
    echo 'DocumentRoot /var/www/html/phpMyFAQ'; \
    echo; \
    echo '<Directory /var/www/html/phpMyFAQ>'; \
    echo '\tOptions -Indexes'; \
    echo '\tAllowOverride none'; \
    echo '</Directory>'; \
    echo '</VirtualHost>'; \
  } | tee "$APACHE_CONFDIR/sites-available/phpmyfaq.conf" \
  && a2ensite phpmyfaq \
  && a2dissite 000-default;

#=== Configure php ===
RUN { \
    echo 'memory_limit = 64M'; \
    echo 'date.timezone = Europe/Paris'; \
  } | tee "$PHP_INI_DIR/php.ini";

#=== Install php dependencies ===
RUN apt-get update && apt-get install -y \
      \
      libfreetype6-dev \
      libjpeg62-turbo-dev \
      libpng12-dev \
      \
      libmcrypt-dev \
  \
  && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
  && docker-php-ext-install -j$(nproc) gd \
  \
  && docker-php-ext-install -j$(nproc) iconv mcrypt \

#=== Download phpMyFAQ source code and install ===
RUN set -xe; \
  \
  fetchDeps=' \
    git \
  '; \
  \
  apt-get update; \
  apt-get install -y --no-install-recommends $fetchDeps; \
  rm -r /var/lib/apt/lists/*; \
  \
  cd /var/www/html; \
  git clone "git://github.com/thorsten/phpMyFAQ.git"; \
  \
  cd ./phpMyFAQ; \
  curl -s https://getcomposer.org/installer | php; \
  php composer.phar install; \
  npm install; \
  bower install; \
  grunt;
  \
  apt-get purge -y --auto-remove $fetchDeps; \
  \
  chown -R "$APACHE_RUN_USER." /var/www/html/phpMyFAQ;

WORKDIR /var/www/html/phpMyFAQ

#=== !!! DEBUG !!! phpinfo !!! REMOVE !!! ===
RUN { \
    echo '<?php'; \
    echo 'phpinfo();'; \
    echo '?>'; \
  } | tee "./info.php";
