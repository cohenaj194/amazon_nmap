#!/usr/bin/env ruby
# frozen_string_literal: true

require 'mail'
require_relative 'shared-functions'

@options = {
  test: false,
  json_path: './output/scannable-instances.json',
  master_path: './output/master-scannable-instances.json',
  scan_account: ENV.fetch('SCAN_ACCOUNT', 'default'),
  bucketname: ENV['BUCKET_NAME'],
  access: ENV['AWS_ACCESS_KEY_ID'],
  secret: ENV['AWS_SECRET_ACCESS_KEY'],
  today: Time.now.strftime('%d').to_s,
  run: false,
  aws_account_number: ENV['AWS_ACCOUNT_NUMBER'],
  aws_account_email: ENV['AWS_ACCOUNT_EMAIL'],
  from_email: ENV['OUTLOOK_EMAIL'],
  from_email_password: ENV['OUTLOOK_EMAIL_PASSWORD'],
  outlook_domain: ENV['OUTLOOK_DOMAIN'],
  pen_test_request_email_recipient: ENV['PEN_TEST_REQUEST_EMAIL_RECIPIENT'],
  bucket_path: ENV['BUCKET_PATH'],
  submittername: ENV['SUBMITTERNAME'],
  companyname: ENV['COMPANYNAME'],
  source_ip: ENV['SOURCE_IP'],
  source_id: ENV['SOURCE_ID']
}
opt_parser = OptionParser.new do |opts|
  opts.banner = <<~EOF
    On the 10th of the month a temporary static list is created from todays ./output/scannable-instances.json in the S3 bucket under the S3 path:
     #{@options[:bucket_path]}/$SCAN_ACCOUNT/temp-scannable-instances.json

    Takes AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY as the default aws variables.
    Note that these are the access keys for the account of your s3 bucket and can be different than your scan account.

    Usage: bundle exec ruby #{__FILE__} -t 10 -z $SCAN_ACCOUNT -b $BUCKET_NAME -a $AWS_ACCESS_KEY_ID -s $AWS_SECRET_ACCESS_KEY \\
            -u foo.bar@whatever.com -r 'test' --from_email foo.bar2@whatever.com --from_pass asdfasdfasdf

    On the 17th of the month the master static list is deleted and replaced with the temporary static list that was created 7 days prior

    Usage: bundle exec ruby #{__FILE__} -t 17 -z $SCAN_ACCOUNT -b $BUCKET_NAME -a $AWS_ACCESS_KEY_ID -s $AWS_SECRET_ACCESS_KEY \\
            -u foo.bar@whatever.com -r 'test'

  EOF
  opts.on('-j', '--json_path path/to/scannable-instances.json', 'json_path') { |path| @options[:json_path] = path }
  opts.on('-m', '--master_path path/to/master-scannable-instances.json', 'master_path') { |master| @options[:master_path] = master }
  opts.on('-z', '--aws_account SCAN_ACCOUNT', 'scan_account') { |scan_account| @options[:scan_account] = scan_account }
  opts.on('-b', '--bucket BUCKETNAME', 'bucketname') { |bucketname| @options[:bucketname] = bucketname }
  opts.on('-p', '--bucket_path BUCKET_PATH', 'bucket_path') { |bucket_path| @options[:bucket_path] = bucket_path }
  opts.on('-a', '--access AWS_ACCESS', 'access') { |access| @options[:access] = access }
  opts.on('-s', '--secret AWS_SECRET', 'secret') { |secret| @options[:secret] = secret }
  opts.on('-t', '--today day_of_month', 'day number') { |today| @options[:today] = today }
  opts.on('-y', '--run', 'will cause the script to send emails') { |r| @options[:run] = r }
  opts.on('--from_email asdf@foobar.com', 'an email address') { |u| @options[:from_email] = u }
  opts.on('--from_pass asdfasdfasdf', 'password to email') { |pass| @options[:from_email_password] = pass }
  opts.on('--test', 'for unit ci testing') { |t| @options[:test] = t }
end.parse!

@s3_client = create_s3_client(@options[:access], @options[:secret])
@s3_resource = create_s3_resource(@options[:access], @options[:secret])

#### FUNCTIONS FOR THE 10th OF THE MONTH ####

def create_ip_diff(current, master)
  # copy of todays list of ips
  diff = current.clone
  # removes old addresses from the new list of ips
  current.each do |address|
    diff.delete(address) if master.include?(address)
  end
  diff
end

def send_mail
  # mail gem cannot parse arrays or hashes
  from_email = @options[:from_email]
  from_email_password = @options[:from_email_password]
  scan_account = @options[:scan_account]
  outlook_domain = @options[:outlook_domain]
  # create mail client
  Mail.defaults do
    mail_hash = {
      address: 'smtp.office365.com',
      port: 587,
      domain: outlook_domain,
      user_name: from_email,
      password: from_email_password,
      authentication: :login,
      enable_starttls_auto: true
    }
    delivery_method :smtp, mail_hash
  end

  # create strings of all ip addresses and all instance ids for the email
  instance_ids = ''
  CSV.foreach('output/scannable-instances.csv', headers: true) do |row|
    instance_ids += row.to_hash['instance_id'] + "\n"
  end

  # create the email body
  message = ''"
  Email aws-security-cust-pen-test@amazon.com with the below information.

  SubmitterName                       #{@options[:submittername]}
  CompanyName                         #{@options[:companyname]}
  EmailAddress                        #{@options[:aws_account_email]}

  Account Name: #{@options[:scan_account]}
  Account Number: #{@options[:aws_account_number]}
  IPs to be scanned: #{get_todays_ip_list.join("\n")}
  Instance IDs: #{instance_ids}
  Source: #{@options[:source_ip]}
  Source ID: #{@options[:source_id]}
  Region: #{aws_regions_list(@options[:access], @options[:secret]).join(', ')}
  timezone: gmt--11
  Bandwidth                       .1
  StartDate: #{(Time.now + (24 * 60 * 60)).strftime('%Y-%m-%d')} 00:00
  EndDate:  #{(Time.now + (90 * 24 * 60 * 60)).strftime('%Y-%m-%d')} 00:00
  "''
  # write out email contents into a file for record keeping
  File.open('./output/email-message.txt', 'w') do |file|
    file.write(message)
  end
  # pen testing will switch 6-7 days after this is sent and we will want this to continue for 90 days

  # create IT ticket if running
  if @options[:run]
    email_recipient = @options[:pen_test_request_email_recipient]
    Mail.deliver do
      from     from_email
      to       email_recipient
      subject  "#{scan_account} Pen Test Request"
      body     message
      add_file './output/scannable-instances.csv'
    end
  end
end

# creates $BUCKET_PATH/$SCAN_ACCOUNT/temp-scannable-instances.json
def bucket_upload
  # directory in the bucket to store the temp-scannable-instances.json
  bucket_directory = "#{@options[:bucket_path]}/#{@options[:scan_account]}/temp-scannable-instances.json"

  # the file will be in the S3 bucket under the path $BUCKET_PATH/$ACCOUNT_NAME/temp-scannable-instances.json
  puts "Uploading to #{@options[:bucketname]}..."
  @s3_resource.bucket(@options[:bucketname]).object(bucket_directory).upload_file(@options[:json_path])
  puts "Uploaded: #{bucket_directory}"
end

def make_new_master_scannable_instances
  # gets the list of ips from todays scannable-instances.json produced by ./describe-addresses.rb
  current = get_ip_list_from_hash(use_ec2_addresses_hash(@options[:json_path]))
  # gets the list of ips from the master-scannable-instances.json produced by ./download-static-ip-list.rb
  master = get_ip_list_from_hash(use_ec2_addresses_hash(@options[:master_path]))

  # diff the current list of ips from the current master list in use to get the delta
  diff = create_ip_diff(current, master)

  # a text file for current delta of ip addresses
  ip_list_file_name = "#{@options[:scan_account]}-monthly-ip-list.txt"

  if !diff.empty?
    # sends the list of new instances to STDOUT
    puts "The new instances of #{@options[:scan_account]} are:"
    puts diff.join("\n")

    File.open("./output/#{ip_list_file_name}", 'w') do |file|
      file.write(current.join("\n"))
    end
  else
    output = "There are no new instances in #{@options[:scan_account]} this month."
    puts output
    File.open("./output/#{ip_list_file_name}", 'w') do |file|
      # a note for email recipient if there is no need to create a new pen test request for the month
      file.write(output)
    end
  end

  # No emails are sent durring unit tests
  send_mail unless @options[:test]

  # creates $BUCKET_PATH/$SCAN_ACCOUNT/temp-scannable-instances.json
  bucket_upload
end

#### end of functions for the 10th of the month ####

#### FUNCTIONS FOR THE 17th OF THE MONTH ####

# downloads temp-scannable-instances.json as the new master-scannable-instances.json
def download_new_master_ip_list(temp_path)
  # reads contents of temp-scannable-instances.json
  # and writes the contents to a new local master-scannable-instances.json
  File.open('./output/master-scannable-instances.json', 'w') do |file|
    file.write(@s3_client.get_object(bucket: @options[:bucketname], key: temp_path).body.read)
  end
end

# checks that master-scannable-instances.json and temp-scannable-instances.json exist in the bucket
def check_bucket_files(master_path, temp_path)
  # checking for temp-scannable-instances.json
  begin
    @s3_client.get_object(
      bucket: @options[:bucketname],
      key: temp_path
    )
  rescue Aws::S3::Errors::NoSuchKey => e
    error_msg = "In the bucket #{@options[:bucketname]} this file might not exist: "
    error_msg += "#{temp_path}\n"
    error_msg += 'If this scan failed to run on the 10th or this is the first month that this aws account is being scanned, '
    error_msg += "then there will not be a temp-scannable-instances.json for this account\n"
    error_msg += e.to_s
    LOGGER.info(error_msg)
    LOGGER.close
    exit 0
  end

  # checking for temp-scannable-instances.json
  begin
    @s3_client.get_object(
      bucket: @options[:bucketname],
      key: master_path
    )
  rescue Aws::S3::Errors::NoSuchKey => e
    error_msg = "In the bucket #{@options[:bucketname]} these files might not exist: "
    error_msg += "#{master_path}\n"
    error_msg += e.to_s
    LOGGER.info(error_msg)
    LOGGER.close
    abort
  end
end

# deletes old master list from bucket and local environment
# downloads temp list as new master list for the local environment
# deletes temp list from the bucket
# uploads temp list as new master list in the S3 bucket
def change_master_scannable_instances
  # check that master-scannable-instances.json exists locally
  master_test = use_ec2_addresses_hash(@options[:master_path])

  # check that master-scannable-instances.json and temp-scannable-instances.json exist in the bucket
  master_path = "#{@options[:bucket_path]}/#{@options[:scan_account]}/master-scannable-instances.json"
  temp_path   = "#{@options[:bucket_path]}/#{@options[:scan_account]}/temp-scannable-instances.json"

  check_bucket_files(master_path, temp_path)

  # delete "$BUCKET_PATH/$SCAN_ACCOUNT/master-scannable-instances.json" from the S3 bucket
  @s3_client.delete_object(
    bucket: @options[:bucketname],
    key: master_path,
    use_accelerate_endpoint: false
  )

  # delete local copy of the old master list, master-scannable-instances.json, from the container
  File.delete(@options[:master_path]) if File.exist?(@options[:master_path])

  # download temp-scannable-instances.json as the new local master-scannable-instances.json
  download_new_master_ip_list(temp_path)

  # delete the old temp-scannable-instances.json in the S3 bucket
  @s3_client.delete_object(
    bucket: @options[:bucketname],
    key: temp_path,
    use_accelerate_endpoint: false
  )

  # upload new local master-scannable-instances.json as the new master list in the bucket
  @s3_resource.bucket(@options[:bucketname]).object(master_path).upload_file(@options[:master_path])
  puts "Uploaded: new #{@options[:bucket_path]}/#{@options[:scan_account]}/master-scannable-instances.json"
end

#### end of functions for the 17th of the month ####

#### MAIN ####
def main
  puts "#{__FILE__} is starting"

  if @options[:today] == '10'
    make_new_master_scannable_instances
  elsif @options[:today] == '17'
    change_master_scannable_instances
  else
    puts "Its not the 10th or the 17th, the master lists for #{@options[:scan_account]} has not been changed."
  end

  puts "#{__FILE__} has finished"
end

main if $PROGRAM_NAME == __FILE__
