# frozen_string_literal: true
require 'ostruct'
require 'http'
require 'yaml'
require 'aws-sdk'

## Scheduled worker regularly runs updates using queued URLs
# e.g.: {"url":"https://localhost:9292/api/v0.1/group/1/update"}
class UpdateWorker
  def initialize(config_file)
    @config = worker_configuration(config_file)
    setup_environment_variables
    @sqs = Aws::SQS::Client.new
  end

  def call
    process_send_sms
  end

  private

  def worker_configuration(config_file)
    puts "CONFIG_FILE: #{config_file}"
    config = OpenStruct.new YAML.load(File.read(config_file))
    puts "AWS_REGION: #{config.AWS_REGION}"
    config
  end

  def setup_environment_variables
    ENV['AWS_REGION'] = @config.AWS_REGION
    ENV['AWS_ACCESS_KEY_ID'] = @config.AWS_ACCESS_KEY_ID
    ENV['AWS_SECRET_ACCESS_KEY'] = @config.AWS_SECRET_ACCESS_KEY
  end

  def find_queue_url
    @sqs.get_queue_url(queue_name: @config.SMS_NOTI_QUEUE).queue_url
  end

  def process_send_sms
    processed = {}
    poller = Aws::SQS::QueuePoller.new(find_queue_url)
    poller.poll(wait_time_seconds: nil, idle_timeout: 5) do |msg|
      sms_invitation = parse_body(msg)
      send_sms_request(sms_invitation) unless processed[sms_invitation]
      processed[sms_invitation] = true
    end
  end

  def parse_body(msg)
    url = JSON.parse(msg.body)['url']
    from = JSON.parse(msg.body)['from']
    event_name = JSON.parse(msg.body)['evt_name']
    event_url = JSON.parse(msg.body)['evt_url']
    to = JSON.parse(msg.body)['to']
    message = "#{from} wants you to attend #{event_name}, check it out here: #{event_url} "
    { to: to, message: message, url: url }
  end

  def send_sms_request(sms_invitation)
    url = sms_invitation[:url]
    message = sms_invitation[:message]
    to = sms_invitation[:to]
    puts "SMS to: #{url} to #{to} + #{message}"
    response = HTTP.post(url, json: sms_invitation)
    puts response
    raise "API failed: #{url}" if response.status >= 400
  end
end

begin
  UpdateWorker.new(ENV['CONFIG_FILE']).call
  puts 'STATUS: SUCCESS'
rescue => e
  puts "STATUS: ERROR (#{e.inspect})"
end
