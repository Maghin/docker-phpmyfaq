FROM php:5.6.30-apache

MAINTAINER MERHYLSTUDIO <maghin@merhylstudio.fr>

#=== Download phpMyFAQ source code ===
ADD http://download.phpmyfaq.de/phpMyFAQ-2.9.6.tar.gz /var/www/html/

#=== Install php dependencies ===
RUN set -xe \
  \
  && apt-get update && apt-get install -y \
      \
      libfreetype6-dev \
      libjpeg62-turbo-dev \
      libpng12-dev \
      \
      libmcrypt-dev \
  && rm -r /var/lib/apt/lists/* \
  \
  && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
  && docker-php-ext-install -j$(nproc) gd \
  \
  && docker-php-ext-install -j$(nproc) iconv mcrypt

#=== fix rights ===
RUN set -xe \
  \
  && chown -R www-data:www-data /var/www/html

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

#=== !!! DEBUG !!! phpinfo !!! REMOVE !!! ===
RUN { \
    echo '<?php'; \
    echo 'phpinfo();'; \
    echo '?>'; \
  } | tee "./info.php";

