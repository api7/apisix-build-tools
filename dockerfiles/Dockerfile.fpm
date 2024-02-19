FROM ubuntu:focal

RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y git \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y ruby ruby-dev rubygems build-essential rpm \
    && gem install dotenv -v 2.8.1 \
    && gem install fpm \
    && fpm --version

CMD /usr/local/bin/fpm