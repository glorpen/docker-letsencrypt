FROM glorpen/puppetizer-base:2.3.0-alpine3.10-6.6.0

LABEL maintainer="Arkadiusz Dzięgiel <arkadiusz.dziegiel@glorpen.pl>"

COPY ./Puppetfile /opt/puppetizer/etc/puppet/puppetfile

RUN /opt/puppetizer/bin/update-modules

RUN apk update \
    && apk add certbot bash \
    && pip3 install consulate==0.6.0 \
    && rm -rf /var/cache/apk/* /root/.cache \
    && sed -i /usr/lib/python3*/site-packages/certbot/log.py -e 's/\(maxBytes=[^,]\+\)/mode="w"/'

COPY ./hiera/ /opt/puppetizer/puppet/hiera/
ADD ./puppet/ /opt/puppetizer/puppet/modules/puppetizer_main/

RUN /opt/puppetizer/bin/build