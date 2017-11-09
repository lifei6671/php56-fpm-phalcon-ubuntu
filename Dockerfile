FROM php:5.6.6-fpm

MAINTAINER Minho <longfei6671@163.com>

COPY conf/php.ini /usr/local/etc/php/php.ini
COPY  conf/www.conf /usr/local/etc/php-fpm.d/www.conf

#Alpine packages
RUN apt-get update && apt-get install -y make g++ re2c \
	libfreetype6-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libpng12-dev \
	libpcre3-dev \
	gcc \
	make \
    bzip2 \
	libbz2-dev \
	libmemcached-dev \
	--no-install-recommends && rm -r /var/lib/apt/lists/*

RUN docker-php-source extract \
	&& cd /usr/src/php/ext/bcmath \
	&& phpize && ./configure --with-php-config=/usr/local/bin/php-config && make && make install \
	&& make clean \
	&& docker-php-source delete
	
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
        && docker-php-ext-install gd \
        && docker-php-ext-install mysqli \
        && docker-php-ext-install bz2 \
        && docker-php-ext-install zip \
        && docker-php-ext-install pdo \
		&& docker-php-ext-install ctype \
		&& docker-php-ext-install mcrypt \
        && docker-php-ext-install pdo_mysql \
		&& docker-php-ext-install mbstring \
        && docker-php-ext-install opcache \
		&& echo "extension=memcached.so" > /usr/local/etc/php/conf.d/memcached.ini \
		&& echo "extension=redis.so" > /usr/local/etc/php/conf.d/phpredis.ini \
		&& echo "extension=phalcon.so" > /usr/local/etc/php/conf.d/phalcon.ini \
		&& echo "extension=igbinary.so" > /usr/local/etc/php/conf.d/igbinary.ini \
		&& echo "extension=bcmath.so" > /usr/local/etc/php/conf.d/bcmath.ini \
		&& echo "zend_extension=xdebug.so" >> /usr/local/etc/php/conf.d/xdebug.ini \
		&& echo "extension=imagick.so" >> /usr/local/etc/php/conf.d/imagick.ini 
		
		
WORKDIR /usr/src/php/ext/

	
RUN set -xe && \
	curl -LO https://github.com/igbinary/igbinary/archive/2.0.5.tar.gz \
	&& tar xzf 2.0.5.tar.gz && cd igbinary-2.0.5 && phpize && ./configure CFLAGS="-O2 -g" --enable-igbinary && make install \
	&& echo "extension=igbinary.so" > /usr/local/etc/php/conf.d/igbinary.ini \
	&& cd .. \
	&& rm -rf igbinary-2.0.5 2.0.5.tar.gz
	
# Compile Memcached 
RUN set -xe && \
	curl -LO https://github.com/php-memcached-dev/php-memcached/archive/2.2.0.tar.gz \
	&& tar xzf 2.2.0.tar.gz \
	&& cd php-memcached-2.2.0 \
	&& phpize \
	&& ./configure && make && make install \
	&& echo "extension=memcached.so" > /usr/local/etc/php/conf.d/memcached.ini \
	&& cd .. \
	&& rm -rf php-memcached-2.2.0  2.2.0.tar.gz
	
# Compile PhpRedis
ENV PHPREDIS_VERSION=3.0.0

RUN set -xe && \
	curl -LO https://github.com/phpredis/phpredis/archive/3.1.4.tar.gz \
	&& tar xzf 3.1.4.tar.gz \
	&&  docker-php-ext-configure phpredis-3.1.4 --enable-redis-igbinary \
	&& docker-php-ext-install phpredis-3.1.4 \
	&& cd .. \ 
	&& rm -rf phpredis-3.1.4 3.1.4.tar.gz
	
ENV PHALCON_VERSION=3.0.1

WORKDIR /usr/src/php/ext/
# Compile Phalcon
RUN set -xe && \
    curl -LO https://github.com/phalcon/cphalcon/archive/v${PHALCON_VERSION}.tar.gz \
    && tar xzf v${PHALCON_VERSION}.tar.gz \
	&& cd cphalcon-${PHALCON_VERSION}/build && ./install \
    && echo "extension=phalcon.so" > /usr/local/etc/php/conf.d/phalcon.ini  \
    && cd .. \
	&& rm -rf v${PHALCON_VERSION}.tar.gz



#ImageMagick
RUN set -xe && \
	curl -LO https://github.com/ImageMagick/ImageMagick/archive/6.9.6-8.tar.gz \
	&& tar xzf 6.9.6-8.tar.gz && cd ImageMagick-6.9.6-8 \
	&& ./configure --with-bzlib=yes --with-fontconfig=yes --with-freetype=yes --with-gslib=yes --with-gvc=yes --with-jpeg=yes --with-jp2=yes --with-png=yes --with-tiff=yes && make clean && make && make install && \
	make clean && ldconfig /usr/local/lib \
	&& cd .. && rm -rf 6.9.6-8.tar.gz ImageMagick-6.9.6-8

RUN set -xe && \
	curl -LO https://github.com/mkoppanen/imagick/archive/3.4.2.tar.gz && \
	tar zxvf  3.4.2.tar.gz && cd imagick-3.4.2 && phpize && ./configure  --with-php-config=/usr/local/bin/php-config --with-imagick=/usr/local/lib && make && make install \
	&& cd .. && rm -rf 3.4.2.tar.gz imagick-3.4.2
	
#Compile XDebug
RUN set -xe && \
	curl -LO https://github.com/xdebug/xdebug/archive/XDEBUG_2_4_1.tar.gz && \
	tar xzf XDEBUG_2_4_1.tar.gz && cd xdebug-XDEBUG_2_4_1 && \
	phpize && ./configure --enable-xdebug && make && make install && \
	cd ../ && rm -rf xdebug-XDEBUG_2_4_1 XDEBUG_2_4_1.tar.gz
	
	
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
RUN ln -s usr/local/bin/docker-entrypoint.sh /entrypoint.sh # backwards compat

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 9000

CMD ["php-fpm"]