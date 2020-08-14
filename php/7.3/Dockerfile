FROM jguyomard/laravel-php:7.3

LABEL author="Valentine Mayaki"
LABEL email="mxvmayaki@gmail.com"

RUN apk --update --no-cache add autoconf g++ make \
    && pecl install -f xdebug-2.9.5 \
    && docker-php-ext-enable xdebug \
    && apk del --purge autoconf g++ make

WORKDIR /var/www/