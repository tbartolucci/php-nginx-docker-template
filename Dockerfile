FROM php:7.2-fpm
WORKDIR /app

# iconv pdo openssl curl mbstring ftp zlib mysqlnd are already enabled
RUN  apt-get update && apt-get install -y git libmcrypt-dev libmemcached-dev libz-dev \
    && docker-php-ext-install pdo_mysql mysqli \
    && pecl install https://pecl.php.net/get/redis-4.0.0.tgz \
    && pecl install https://pecl.php.net/get/xdebug-2.6.0 \
    && pecl install https://pecl.php.net/get/memcached-3.0.4 \
    && pecl install https://pecl.php.net/get/mcrypt-1.0.1 \
    && docker-php-ext-enable redis mcrypt xdebug memcached

COPY ./php.ini /usr/local/etc/php

# Copy all code to the image
COPY ./src /app
RUN php composer.phar install
 # && /app/vendor/bin/phpunit  -- still need to figure out CSR unit tests

# Copy everything else and build
RUN cp -rp /app/* /var/www/

RUN apt update -y && \
   apt install -y nginx

RUN rm /etc/nginx/nginx.conf
COPY ./nginx.conf /etc/nginx

RUN mkdir -p /etc/nginx/conf.d/certs && \
   openssl req -x509 -newkey rsa:2048 \
   -keyout /etc/nginx/conf.d/certs/server.key \
   -out /etc/nginx/conf.d/certs/server.cer \
   -days 1460 -nodes -subj "/C=US/ST=New Jersey/L=Westfield/O=TheTomb/CN=the-tomb.net"

RUN mkdir -p /static
COPY ./revision.txt /static/
COPY ./start.py /

RUN apt update -y && \
   apt install -y dos2unix python3 python3-pip jq gnupg && \
   pip3 install requests boto3 awscli --upgrade && \
   dos2unix /start.py

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# to see stdout from python in docker logs
ENV PYTHONUNBUFFERED=1

EXPOSE 443

ENTRYPOINT ["python3", "/start.py"]