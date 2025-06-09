FROM public.ecr.aws/l1f2y5v8/shekel-mobility/php-fpm:8.0.2 AS base

# Set working directory
WORKDIR /var/www

FROM base AS dev

RUN curl -fsSL https://get.docker.com | sh
RUN pecl install -o -f xdebug \
	&& docker-php-ext-enable xdebug
RUN echo "xdebug.mode=debug" >> /usr/local/etc/php/conf.d/xdebug.ini \
	&& echo "xdebug.start_with_request=trigger" >> /usr/local/etc/php/conf.d/xdebug.ini

RUN git config --global --add safe.directory /var/www

