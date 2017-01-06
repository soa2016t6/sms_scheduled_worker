FROM soumyaray/ruby-http:2.3.1

WORKDIR /worker

ADD Gemfile .
ADD Gemfile.lock .
RUN bundle install

ADD send_invite_sms.rb .

ENTRYPOINT ruby send_invite_sms.rb
