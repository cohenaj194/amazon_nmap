#!/usr/bin/env ruby
require 'facets'
require_relative 'shared-functions'

@options = {
  scan_account: ENV.fetch('SCAN_ACCOUNT','default'),
  bucketname: ENV['BUCKET_NAME'],
  access: ENV['AWS_ACCESS_KEY_ID'],
  secret: ENV['AWS_SECRET_ACCESS_KEY'],
  today: Time.now.strftime("%Y-%m-%d"),
  yesterday: ( Time.now - (24*60*60) ).strftime("%Y-%m-%d"),
  test: false,
  bucket_path: ENV['BUCKET_PATH'],
  # port_list: JSON.parse(ENV.fetch('PORT_LIST','["21","22","23","25","53","80","110","137","138","139","443","1434","2222","3389","5985","5986","7000","8020","8080"]'))
}
opt_parser = OptionParser.new do |opts|
  opts.banner = <<-EOF
Description: checks over todays gnmap files, 
             checks for common ports that should not be open and diffs from the previous days gnmap files
             produces $REGION-common-open-ports.json and $REGION-diff-open-ports.json

Requires: output/all-instances.csv, output/*-nmap-results.gnmap

Usage: bundle exec ruby #{__FILE__} 

Takes AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY as the default aws variables.
Note that these are the access keys for the account of your s3 bucket and can be different than your scan account. 

Uses todays and yesterdays date as the default date parameters.
Older dates can be tested using the optional cli arguments.

Example: bundle exec ruby nmap-diff.rb -z $SCAN_ACCOUNT -b $BUCKET_NAME -a $AWS_ACCESS_KEY_ID -s $AWS_SECRET_ACCESS_KEY -t 2016-11-20 -y 2016-11-19 --test
EOF
  opts.on('-z', '--aws_account scan_account', 'scan_account') { |scan_account| @options[:scan_account] = scan_account }
  opts.on('-b', '--bucket BUCKETNAME', 'bucketname') { |bucketname| @options[:bucketname] = bucketname }
  opts.on('-a', '--access AWS_ACCESS', 'access') { |access| @options[:access] = access }
  opts.on('-s', '--secret AWS_SECRET', 'secret') { |secret| @options[:secret] = secret }
  opts.on('-t', '--today todays_date_y_m_d', 'today') { |today| @options[:today] = today }
  opts.on('-y', '--yest yesterdays_date_y_m_d', 'yesterday') { |yesterday| @options[:yesterday] = yesterday }
  opts.on('-a', '--test', '--test run against spec gnmap files') { |t| @options[:test] = t }
end.parse!

@s3_client = create_s3_client(@options[:access], @options[:secret])
@s3_resource = create_s3_resource(@options[:access], @options[:secret])

def download_yesterdays_gnmap
  # gets the list of yesterdays *.gnmap files for the current account
  yesterdays_gnmap = @s3_resource.bucket(@options[:bucketname]).objects(
    prefix: "#{@options[:bucket_path]}/#{@options[:scan_account]}/#{@options[:yesterday]}"
  ).collect(&:key).select{|file| file.include?(".gnmap")}

  # saving contents of gnmap files in a hash
  yesterdays_gnmap_hash = Hash.new

  yesterdays_gnmap.each do | file |
    yesterdays_gnmap_hash[file] = @s3_client.get_object({ bucket: @options[:bucketname], key: file }).body.read
  end

  return yesterdays_gnmap_hash

end

def get_todays_gnmap
  # gets the list of todays *.gnmap files
  # these are stored in the current directory after nmap-port-scan.rb runs
  todays_gnmap = Dir.glob('./output/*.gnmap')

  # saving contents of gnmap files in a hash
  todays_gnmap_hash = Hash.new
  todays_gnmap.each do | file |
    todays_gnmap_hash[file]=File.open(file).read
  end
  return todays_gnmap_hash
end

# this check will look over all instances, looks for ports that should never be open
# even the the instances that are unchanged from yesterday
def common_open_port_check(new_gnmap, rspec=false)
  common_ports = Array.new 
  port_list = [21,22,23,25,53,80,110,137,138,139,443,1434,2222,3389,5985,5986,7000,8020,8080]

  # checking for common ports that should not be open
  new_gnmap.each do | host |
    port_check_boolean = false

    # checks a host for any common ports, included in the list port_list
    port_list.each do | port_num |
      port_check_boolean = host.include?(" #{port_num}/open")
      if port_check_boolean == true
        break
      end
    end

    if port_check_boolean
      # gets the ip from the gnmap info
      host_ip = host.split[1]
      # rspec cannot open the all-instances.csv file
      if rspec
        host_info = []
      else
        host_info = get_aws_instance_info(host_ip)
      end
      # adds this info together
      host_info.push("host" => host_ip)
      host_info.push("open_ports" => clean_up_port_info(host))
      # adds the combined host info into a list 
      common_ports.push(host_info)
    end
  end

  return common_ports
end

# this check will only look over instances that were changed from yesterday, 
# this includes: new instances, instances whose port status has changed
def diff_open_port_check(old_gnmap, new_gnmap, rspec=false)
  # the array that is written into the port delta file
  open_ports = Array.new
  # will contain the port info from both days for instances where there is a change
  open_ports_hash = Hash.new
  # after the string for each line of gnmap info is split up 
  # it is then inserted into hashes for either the new or old gnmap info
  old_gnmap_hash = Hash.new
  new_gnmap_hash = Hash.new

  old_gnmap.each do | host |
    old_gnmap_hash[host.split[1]] = clean_up_port_info(host)
  end

  new_gnmap.each do | host |
    new_gnmap_hash[host.split[1]] = clean_up_port_info(host)
  end

  # compares the values for each host in the latest gnmap file and stores instances that had some change
  new_gnmap_hash.keys.each do | host |
    # adds new hosts to delta if it does not exist in the old one
    if !old_gnmap_hash.keys.include?(host)
      open_ports_hash[host] = {"old_ports" => ["new host no results from yesterday"], "new_ports" => new_gnmap_hash[host]}
    # adds host to delta if open ports changed
    # adds both todays and yesterdays results
    elsif collect_ports(old_gnmap_hash[host]).frequency != collect_ports(new_gnmap_hash[host]).frequency
      open_ports_hash[host] = {"old_ports" => old_gnmap_hash[host], "new_ports" => new_gnmap_hash[host]}
    end
  end

  # matches instance info
  open_ports_hash.each do | host, ports |
    # gets the matching info from all-instances.csv

    # rspec cannot open the all-instances.csv file
    if rspec
      host_info = []
    else
      host_info = get_aws_instance_info(host)
    end
    # filter out staging instances, because they turn on and off frequently, causing false positives
    if !host_info[0].to_s.include?("staging")
      # adds this info together with the delta
      host_info.push("host" => host)
      host_info.push(ports)
      # adds the combined host info into a list 
      open_ports.push(host_info)
    end
  end

  # if there is a delta then a file is created
  return open_ports
end

def collect_ports(host_list)
  return host_list.map{ |host| host["port"] }
end

def clean_up_port_info(host)
  # selects only the port info from each line of the gnmap files and stores that in hashes
  # note that the port substrings do not contain the characters '.', '(' or ')'
  port_array = host.split.select {|string| !string[/\d/].nil? && string[/\(/].nil? && string[/\)/].nil? && string[/\./].nil? }

  # takes each selected port string and breaks it down futher into cleaner info
  clean_ports=[]
  port_array.each do |port_string|
    clean_ports.push({
      "port" => port_string.split(/\//)[0],
      "state" => port_string.split(/\//)[1],
      "protocol" => port_string.split(/\//)[2],
      "service" => port_string.split(/\//)[4]
    })
  end
  return clean_ports
end

def get_aws_instance_info(host)
  begin
    return File.open("#{Dir.pwd}/output/all-instances.csv").grep(/#{host}/)
  rescue StandardError => e
    error_msg = "cannot open all-instances.csv\n"
    error_msg+= e.to_s
    LOGGER.warn(error_msg)
    LOGGER.close
  end
end

#### MAIN ####
def main
  puts "#{__FILE__} is starting"
    
  # collects todays and yesterdays gnmap output to compare the two
  yesterdays_gnmap_hash = download_yesterdays_gnmap
  todays_gnmap_hash = get_todays_gnmap
  
  aws_regions_list(@options[:access], @options[:secret]).each do | region |
    new_gnmap, old_gnmap = [], []
    # if there are instances in the current region today a gnmap file should exist for today
    todays_gnmap_hash.keys.each do | file |
      if file.include?(region)
        # collects gnmap output of hosts with ports that were scanned
        new_gnmap=todays_gnmap_hash[file].split(/\n/).reject{| host | host.include?("()\tStatus: Up") || ! host.include?("Host:")}
      end
    end
    yesterdays_gnmap_hash.keys.each do | file |
      if file.include?(region)
        # collects gnmap output of hosts with ports that were scanned
        old_gnmap=yesterdays_gnmap_hash[file].split(/\n/).reject{| host | host.include?("()\tStatus: Up") || ! host.include?("Host:")}
      end
    end

    if @options[:test]
      old_gnmap = JSON.parse(File.read('./spec/fixtures/old_gnmap.json'))
      new_gnmap = JSON.parse(File.read('./spec/fixtures/new_gnmap.json'))
    end
  
    # if neither array is empty then there is a gnmap file for both today and yesterday so we will create file deltas
    if new_gnmap != [] && old_gnmap != []
  
      # creating common open port list
      # checking for common ports that should not be open
      common_ports = common_open_port_check(new_gnmap)

      # if any instances contain these common open ports
      if common_ports != []
        File.open("./output/#{region}-common-open-ports.json","w") do |file|
          file.write(common_ports.to_json)
        end
      end
  
      # creating port delta
      # looking for any other new hosts with open ports, or hosts whos ports have changed
      open_ports = diff_open_port_check(old_gnmap, new_gnmap)
      if open_ports != []
        File.open("./output/#{region}-diff-open-ports.json","w") do |file|
          file.write(open_ports.to_json)
        end
      end
      
      puts "Compared gnmap output in region: #{region} for #{@options[:today]} to #{@options[:yesterday]}"
    else
      puts "** There are no instances in region or there is no gnmap file for either today or yesterday: region: #{region}, date: #{@options[:today]}"
    end
  end
  
  puts "#{__FILE__} has finished"
end

if $0 == __FILE__
  main
end
