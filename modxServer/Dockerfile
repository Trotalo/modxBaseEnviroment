FROM php:7.3-apache

MAINTAINER Camilo Casadiego <camilo.casadiego@trotalo.com> (@vh)

LABEL description="Image based up ont https://github.com/modxcms/docker-modx to hold PR learning site"

#Arguments and variables definitions
ARG MODX_VERSION=2.8.1
ARG MODX_SHA1=7dd95a25be5989a03ce58ef77adce79b341aa1f4
ARG MODX_SERVER_ROUTE=192.168.0.104
ARG MODX_DB_NAME=modx
ARG TMP_STORE_ARG=/tmp/modx

ENV TMP_STORE=$TMP_STORE_ARG
ENV SITE_BACKUP=$SITE_BACKUP_ARG
ENV CORE_BACKUP=$CORE_BACKUP_ARG
ENV HT_FILENAME=$TMP_STORE/siteConfig/.htaccess
ENV DB_FILENAME=$TMP_STORE/siteConfig/modx.sql

RUN a2enmod rewrite

RUN mkdir -p $TMP_STORE/ \
    && chown -R www-data:www-data $TMP_STORE/

#Uncoment for development enviroment
ADD certs/ssl.crt /etc/apache2/ssl/ssl.crt
ADD certs/ssl.key /etc/apache2/ssl/ssl.key
ADD ./configFiles/default /etc/apache2/sites-available/000-default.conf
RUN echo "Running development enviroment" \
    && a2enmod ssl \
    && mkdir -p /var/run/apache2/ \
    && mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

# install the PHP extensions we need
RUN apt-get update && apt-get install -y libpng-dev libjpeg-dev unzip sudo libgmp-dev libxml2-dev git mariadb-client \
    && rm -rf /var/lib/apt/lists/* \
	&& ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h \
	&& docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
	&& docker-php-ext-install gd soap opcache mysqli pdo pdo_mysql gmp \
	&& curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install Composer
#RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
 #   && git clone https://github.com/modmore/Gitify.git $TMP_STORE_ARG/Gitify
    #&& cd $TMP_STORE_ARG/Gitify \
    #&& composer install --no-dev \
    #&& mv $TMP_STORE_ARG/Gitify/vendor/kbjr/git.php/Git.php $TMP_STORE_ARG/Gitify/vendor/kbjr/git.php/git.php \
    #&& composer install --no-dev \
    #&& chmod +x Gitify

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
		} > /usr/local/etc/php/conf.d/opcache-recommended.ini

# set timezone
RUN { \
		echo 'date.timezone=GMT+0'; \
	} > /usr/local/etc/php/conf.d/datetime.ini

#Volumne usage
#VOLUME /var/www/


# Download specified modx version ${MODX_VERSION}
RUN curl -o modx.zip -SL http://modx.com/download/direct/modx-${MODX_VERSION}-pl.zip \
	&& echo "$MODX_SHA1 *modx.zip" | sha1sum -c - \
	&& unzip -q modx.zip -d /usr/src \
  && mv /usr/src/modx-${MODX_VERSION}-pl /usr/src/modx \
  && find /usr/src/modx -name 'ht.access' -exec bash -c 'mv $0 ${0/ht.access/.htaccess}' {} \; \
  && rm modx.zip \
	&& chown -R www-data:www-data /usr/src/modx



#Switched to single run to save one step, can be used to work with local files instead of redownload
#ADD ./backup/core.zip $TMP_STORE/core.zip
#ADD ./backup/siteFiles.zip $TMP_STORE/siteFiles.zip

ADD ./configFiles/htaccess.site $HT_FILENAME
ADD ./configFiles/modxExtras $TMP_STORE/modxExtras
ADD ./.gitify $TMP_STORE/.gitify
#ADD ./PRBackup/modx.sql $DB_FILENAME

#update mutiple ht acces and database backup files
RUN sed -i "s,SERVER_ADDRESS,$MODX_SERVER_ROUTE,g" $HT_FILENAME
    #&& sed -i "s,SERVER_ADDRESS,$MODX_SERVER_ROUTE,g" $DB_FILENAME \
    #&& sed -i "s,DB_NAME,$MODX_DB_NAME,g" $DB_FILENAME

#We copy the prod php ini
#RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

COPY docker-entrypoint.sh /entrypoint.sh
RUN ["chmod", "+x", "/entrypoint.sh"]

ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]
