#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'shared-functions'

@options = {
  test: false,
  scan_account: ENV.fetch('SCAN_ACCOUNT', 'default'),
  bucketname: ENV['BUCKET_NAME'],
  access: ENV['AWS_ACCESS_KEY_ID'],
  secret: ENV['AWS_SECRET_ACCESS_KEY'],
  bucket_path: ENV['BUCKET_PATH']
}
opt_parser = OptionParser.new do |opts|
  opts.banner = <<~EOF
    Description: downloads the static list of ips to scan for an aws account master-scannable-instances.json

    Usage: bundle exec ruby #{__FILE__}

    Takes AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY as the default aws variables.
    Note that these are the access keys for the account of your s3 bucket and can be different than your scan account.

    Example: bundle exec ruby #{__FILE__} -z $SCAN_ACCOUNT -b $BUCKET_NAME -a $AWS_ACCESS_KEY_ID -s $AWS_SECRET_ACCESS_KEY
  EOF
  opts.on('-z', '--aws_account scan_account', 'scan_account') { |scan_account| @options[:scan_account] = scan_account }
  opts.on('-b', '--bucket BUCKETNAME', 'bucketname') { |bucketname| @options[:bucketname] = bucketname }
  opts.on('-p', '--bucket_path BUCKET_PATH', 'bucket_path') { |bucket_path| @options[:bucket_path] = bucket_path }
  opts.on('-a', '--access AWS_ACCESS', 'access') { |access| @options[:access] = access }
  opts.on('-s', '--secret AWS_SECRET', 'secret') { |secret| @options[:secret] = secret }
  opts.on('--test', 'for unit ci testing') { |t| @options[:test] = t }
end.parse!

def download_master_ip_list
  s3 = create_s3_client(@options[:access], @options[:secret])

  begin
    master_json = s3.get_object(
      bucket: @options[:bucketname],
      key: "#{@options[:bucket_path]}/#{@options[:scan_account]}/master-scannable-instances.json"
    ).body.read
  rescue Aws::S3::Errors::NoSuchKey => e
    LOGGER.warn("No such file #{@options[:bucket_path]}/#{@options[:scan_account]}/master-scannable-instances.json, consider creating one.")
    master_json = s3.get_object(
      bucket: @options[:bucketname],
      key: "#{@options[:bucket_path]}/default/master-scannable-instances.json"
    ).body.read
  end

  File.open('./output/master-scannable-instances.json', 'w') do |file|
    file.write(master_json)
  end

  if @options[:test]
    master_csv = s3.get_object(
      bucket: @options[:bucketname],
      key: "#{@options[:bucket_path]}/#{@options[:scan_account]}/master-scannable-instances.csv"
    ).body.read

    File.open('./output/master-scannable-instances.csv', 'w') do |file|
      file.write(master_csv)
    end
  end
end

#### MAIN
def main
  puts "#{__FILE__} is starting"
  download_master_ip_list
  puts "#{__FILE__} has finished"
end

main if $PROGRAM_NAME == __FILE__
