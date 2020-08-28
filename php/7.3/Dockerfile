FROM jguyomard/laravel-php:7.3

LABEL author="Valentine Mayaki"
LABEL email="mxvmayaki@gmail.com"

RUN apk --update --no-cache add autoconf g++ make \
    && pecl install -f xdebug-2.9.5 \
    && docker-php-ext-enable xdebug \
    && apk del --purge autoconf g++ make
RUN docker-php-ext-install mysqli && docker-php-ext-enable mysqli

RUN apk add --no-cache freetype libpng libjpeg-turbo freetype-dev libpng-dev libjpeg-turbo-dev && \
  docker-php-ext-configure gd \
    --with-gd \
    --with-freetype-dir=/usr/include/ \
    --with-png-dir=/usr/include/ \
    --with-jpeg-dir=/usr/include/ && \
  NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) && \
  docker-php-ext-install -j${NPROC} gd && \
  apk del --no-cache freetype-dev libpng-dev libjpeg-turbo-dev

WORKDIR /var/www/
