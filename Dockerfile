FROM ruby:2.3
RUN apt-get -y update && apt-get -y install libxslt-dev libxml2-dev

ADD . /gem
WORKDIR /gem

RUN gem install builder

RUN bundle install