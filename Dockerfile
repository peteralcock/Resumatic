FROM ruby:3.0.3
RUN apt-get install -y imagemagick libmagickwand-dev  curl  libxml2-dev  sqlite3 libsqlite3-dev
RUN mkdir /app
WORKDIR /app
RUN apt update
RUN apt  upgrade -y
RUN apt install nodejs -y
RUN gem install searchkick
RUN gem install searchjoy
RUN gem install ffaker
RUN gem install presume
RUN gem install sinatra
RUN gem install sequel
RUN gem install dotenv
RUN gem install similar_text
RUN gem install mongoid -v '4.0.0'
RUN gem install bson_ext
RUN gem install activerecord
RUN gem install dotenv
RUN gem install docx
RUN gem install presume
RUN gem install doc_ripper
RUN gem install open3
RUN gem install yomu
RUN gem install string_score
RUN gem install mongoid
RUN gem install sinatra-contrub
RUN gem install curb
RUN gem install sqlite3
COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock
RUN bundle install --without development test
COPY . .
RUN bundle install
EXPOSE 4567
CMD /usr/bin/ruby api.rb
