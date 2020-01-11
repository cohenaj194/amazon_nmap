#!/usr/bin/env ruby
# frozen_string_literal: true

require 'time'
require 'pathname'
require_relative 'shared-functions'

@options = {
  bucketname: ENV['BUCKET_NAME'],
  access: ENV['AWS_ACCESS_KEY_ID'],
  secret: ENV['AWS_SECRET_ACCESS_KEY'],
  bucket_path: ENV['BUCKET_PATH'],
  scan_account: ENV.fetch('SCAN_ACCOUNT', 'default')
}
OptionParser.new do |opts|
  opts.banner = <<~EOF
    Description: Uploads any files to an S3 bucket, whose names appear in #{Dir.pwd}/file-names.txt

    Takes AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY as the default aws variables.
    Note that these are the access keys for the account of your s3 bucket and can be different than your scan account.

    Usage: bundle exec ruby #{__FILE__} -z $SCAN_ACCOUNT -b $BUCKET_NAME --bucket_path $BUCKET_PATH -a $AWS_ACCESS_KEY_ID -s $AWS_SECRET_ACCESS_KEY
  EOF
  opts.on('-b', '--bucket BUCKETNAME', 'bucketname') { |bucketname| @options[:bucketname] = bucketname }
  opts.on('-p', '--bucket_path BUCKET_PATH', 'bucket_path') { |bucket_path| @options[:bucket_path] = bucket_path }
  opts.on('-z', '--aws_account SCAN_ACCOUNT', 'scan_account') { |scan_account| @options[:scan_account] = scan_account }
  opts.on('-a', '--access ACCESS', 'access') { |access| @options[:access] = access }
  opts.on('-s', '--secret SECRET', 'secret') { |secret| @options[:secret] = secret }
end.parse!

# copies the files that are listed in ./output/ to the S3 bucket with new names that includes timestamps
FILES = Dir.glob('./output/*')

# create a timestamp that will go at the begining of each file
TIME_STAMP = Time.now.utc.iso8601.to_s

# path to the directory in S3 for account files
BUCKET_DIRECTORY = "#{@options[:bucket_path]}/#{@options[:scan_account]}/#{TIME_STAMP}"

#### MAIN
def main
  puts "#{__FILE__} is starting"

  # create s3 resource
  s3_resource = create_s3_resource(@options[:access], @options[:secret])

  puts "Uploading to #{@options[:bucketname]}..."
  FILES.each do |file_name|
    bucket_file_name = "#{TIME_STAMP}-#{Pathname(file_name).relative_path_from(Pathname('./output'))}"
    s3_resource.bucket(@options[:bucketname]).object("#{BUCKET_DIRECTORY}/#{bucket_file_name}").upload_file(file_name)
    puts "Uploaded: #{BUCKET_DIRECTORY}/#{bucket_file_name}"
  end

  puts "#{__FILE__} has finished"
end

main if $PROGRAM_NAME == __FILE__
