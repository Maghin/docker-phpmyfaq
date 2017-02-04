FROM php:5.6.30-apache

MAINTAINER MERHYLSTUDIO <maghin@merhylstudio.fr>

#=== Add phpMyFAQ source code ===
ADD phpMyFAQ-2.9.6.tar.gz .

#=== Install gd (php dependencie) ===
RUN set -xe \
  \
  && buildDeps=' \
    libpng12-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
  ' \
  \
  && apt-get update && apt-get install -y ${buildDeps} \
  \
  && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
  && docker-php-ext-install gd \
  \
  && apt-get purge -y ${buildDeps} \
  && rm -rf /var/lib/apt/lists/*

#=== Install other php dependencies ===
RUN set -xe \
  \
  && apt-get update && apt-get install -y \
      \
      libmcrypt-dev \
      zlib1g-dev \
      libxml2-dev \
      libldap2-dev \
      file \
      \
  && rm -r /var/lib/apt/lists/* \
  \
  && docker-php-ext-install iconv mcrypt zip soap mysqli json xmlwriter ldap fileinfo

#=== Fix rights ===
RUN set -xe \
  \
  && chown -R www-data:www-data ./phpmyfaq

#=== Configure apache ===
RUN { \
    echo '<VirtualHost *:80>'; \
    echo 'ServerName phpmyfaq'; \
    echo 'DocumentRoot /var/www/html/phpmyfaq'; \
    echo; \
    echo '<Directory /var/www/html/phpmyfaq>'; \
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

