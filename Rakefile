# frozen_string_literal: true

require 'yaml'

# Docker tasks
namespace :docker do
  USERNAME = 'isaacmtz90'.freeze
  WORKER = 'send_invite_sms.rb'.freeze
  IMAGE = 'sms-sender'.freeze
  VERSION = '0.1.0'.freeze
  CONFIG_FILE = 'config.yml'.freeze

  desc 'Run the Docker image as a worker'
  task :run do
    puts "\nRUNNING WORKER WITH LOCAL CONTEXT"
    sh "docker run -e \"CONFIG_FILE=#{CONFIG_FILE}\" --rm -it " \
       "-v \"$PWD\":/worker -w /worker  --net=\"host\" " \
       "#{USERNAME}/#{IMAGE}:#{VERSION} ruby #{WORKER}"
  end

  desc 'Build Docker image'
  task :build do
    puts "\nBUILDING WORKER IMAGE"
    sh "docker build --rm --force-rm -t #{USERNAME}/#{IMAGE}:#{VERSION} ."
  end

  desc 'Push Docker image to Docker Hub'
  task :push do
    puts "\nPUSHING IMAGE TO DOCKER HUB"
    sh "docker push #{USERNAME}/#{IMAGE}:#{VERSION}"
  end
end

namespace :iron do
  desc 'Register image as a worker on iron.io'
  task :register do
    puts "\nREGISTERING WORKER IMAGE WITH IRON.IO"
    sh "iron register #{USERNAME}/#{IMAGE}:#{VERSION}"
  end
end

# NOTE: only need to register worker image once (re-registering updates iron.io revision number)
desc 'Deploy by building and pushing Docker image, registering with iron.io'
task deploy: ['docker:build', 'docker:push', 'iron:register']

namespace :queue do
  # sh 'bundle install'
  # require 'aws-sdk'
  config = OpenStruct.new YAML.load(File.read('config.yml'))

  desc "Create SQS queue for Shoryuken"
  task :create do
    sqs = Aws::SQS::Client.new(region: config.AWS_REGION)

    begin
      queue = sqs.create_queue(queue_name: config.UPDATE_QUEUE)
      puts "Queue #{config.UPDATE_QUEUE} created on #{config.AWS_REGION}"
    rescue => e
      puts "Error creating queue: #{e}"
    end
  end

  task :purge do
    config = FaceGroupAPI.config
    sqs = Aws::SQS::Client.new(region: config.AWS_REGION)

    begin
      url = sqs.get_queue_url({ queue_name: config.UPDATE_QUEUE })
      queue = sqs.purge_queue({ queue_url: url.queue_url})
      puts "Queue #{config.UPDATE_QUEUE} purged"
    rescue => e
      puts "Error purging queue: #{e}"
    end
  end
end
