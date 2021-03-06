FROM glorpen/puppetizer-base:3.2.0-alpine3.12-6.10.0

LABEL maintainer="Arkadiusz Dzięgiel <arkadiusz.dziegiel@glorpen.pl>"

COPY ./Puppetfile /opt/puppetizer/etc/puppet/puppetfile

RUN /opt/puppetizer/bin/update-modules

# bash is needed for puppet-letsencrypt hooks
RUN apk update \
    && apk add certbot bash py3-pip \
    && pip3 install consulate==0.6.0 \
    && rm -rf /var/cache/apk/* /root/.cache \
    && sed -i /usr/lib/python3*/site-packages/certbot/_internal/log.py -e 's/\(maxBytes=[^,]\+\)/mode="w"/'

COPY ./hiera/ /opt/puppetizer/puppet/hiera/
ADD ./puppet/ /opt/puppetizer/puppet/modules/puppetizer_main/
ADD proxy-wait.py /usr/local/bin/letsencrypt-wait-for-proxy

RUN /opt/puppetizer/bin/build
