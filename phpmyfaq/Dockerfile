FROM php:5.6.30-apache

MAINTAINER MERHYLSTUDIO <maghin@merhylstudio.fr>

#=== Add phpMyFAQ source code ===
ADD phpMyFAQ-2.9.6.tar.gz .

#=== Install gd (php dependencie) ===
RUN set -xe; \
  \
  buildDeps=' \
    libpng12-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
  ' \
  && apt-get update && apt-get install -y ${buildDeps} \
  \
  && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
  && docker-php-ext-install gd \
  \
  && apt-get purge -y ${buildDeps} \
  && rm -rf /var/lib/apt/lists/*
 
#=== Install ldap (php dependencie) ===
RUN set -xe; \
  \
  buildDeps=' \
    libldap2-dev \
  ' \
  && apt-get update && apt-get install -y ${buildDeps} \
  \
  && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
  && docker-php-ext-install ldap \
  \
  && apt-get purge -y ${buildDeps} \
  && rm -rf /var/lib/apt/lists/*
 
#=== Install other php dependencies ===
RUN set -xe; \
  \
  runtimeDeps=' \
    re2c \
    libmcrypt-dev \
    file \
    zlib1g-dev \
    libxml2-dev \
  ' \
  && apt-get update && apt-get install -y ${runtimeDeps} \
  \
  && docker-php-ext-install mcrypt fileinfo zip soap mysqli json \
  \
  && rm -rf /var/lib/apt/lists/*

#=== Fix rights ===
RUN set -xe; \
  \
  folders=' \
    ./phpmyfaq/attachments \
    ./phpmyfaq/data \
    ./phpmyfaq/images \
  ' \
  && mkdir ${folders} \
  && chmod 775 ${folders} \
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
  && a2dissite 000-default \
  && echo "ServerName localhost" >> "$APACHE_CONFDIR/apache2.conf"

#=== Configure php ===
RUN { \
    echo 'memory_limit = 64M'; \
    echo 'date.timezone = Europe/Paris'; \
  } | tee "$PHP_INI_DIR/php.ini"

#=== !!! DEBUG !!! phpinfo !!! REMOVE !!! ===
RUN { \
    echo '<?php'; \
    echo 'phpinfo();'; \
    echo '?>'; \
  } | tee "./info.php"

