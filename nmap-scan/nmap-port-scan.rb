#!/usr/bin/env ruby
# frozen_string_literal: true

# NOTE: this script may break if not using nmap cli version 7.30 or 6.40
require_relative 'shared-functions'
require 'yaml'

# creating logger
LOGGER = Logger.new(STDERR)
NMAP_INSTANCE_ADDRESS = ENV['SOURCE_IP']
SSH_COMMAND = 'ssh -i /nmap-scan/nmap_keypair.pem -o ControlMaster=auto -o ControlPersist=60s -o ControlPath="/tmp/ssh-%h-%p-%r"'

@options = {
  json_path: './output/master-scannable-instances.json'
}
opt_parser = OptionParser.new do |opts|
  opts.banner = <<~EOF
    WARNING: Do not run this from any source other than an ec2 instance with a public IP address approved by AWS
             Those who do will suffer the wrath of an "Amazon EC2 Abuse Report"

    Usage: bundle exec ruby #{__FILE__}
  EOF
  opts.on('-p', '--json_path path/to/master-scannable-instances.json', 'json_path') { |path| @options[:json_path] = path }
end.parse!

def check_exit_status(exit_status, scan_results)
  if exit_status != 0
    error_msg = "nmap or ssh is broken and has refused to run, exiting with a status of #{exit_status}\n"
    error_msg += "#{scan_results}\n"
    error_msg += e.to_s
    LOGGER.warn(error_msg)
    LOGGER.close
    abort
  end
end

# gathers up all public ips of a region into a list
def grab_scannable_instances(address_blob, active_addresses)
  # list to hold all addresses of a region
  ec2_addresses_list = []
  address_blob.each do |address|
    # gathers all ip addresses for a region and pushes all of them to ec2_addresses_list
    # if they are still active in the account
    ec2_addresses_list.push(address['public_ip_address']) if active_addresses.include?(address['public_ip_address'])
  end
  ec2_addresses_list
end

def scan_ports(region, ec2_addresses_list)
  # edits nmap input file list-of-ips.txt with ip addresses of current region
  scan_results = `#{SSH_COMMAND} centos@#{NMAP_INSTANCE_ADDRESS} 'cd /home/centos/scans/ && echo "#{ec2_addresses_list.join("\n")}" > list-of-ips.txt'`
  check_exit_status($CHILD_STATUS.exitstatus, scan_results)
  # checks list-of-ips.txt
  scan_results = `#{SSH_COMMAND} centos@#{NMAP_INSTANCE_ADDRESS} 'cd /home/centos/scans/ && cat list-of-ips.txt'`
  check_exit_status($CHILD_STATUS.exitstatus, scan_results)
  puts "IP's to scan for #{region}: \n#{scan_results}\n"
  # run nmap against all addresses of the current region
  # creates 3 output files on instance: output.xml output.nmap and output.gnmap
  scan_results = `#{SSH_COMMAND} centos@#{NMAP_INSTANCE_ADDRESS} 'cd /home/centos/scans/ && nmap -sV -v -A midnight_port_scan -Pn -n --top-ports 1000 --max-rtt-timeout 500ms -oA output -iL list-of-ips.txt'`
  check_exit_status($CHILD_STATUS.exitstatus, scan_results)
  # moves output files of each type into the S3 bucket
  %w[
    gnmap
    nmap
    xml
  ].each do |file_type|
    # creates a filename from the region and file type
    file_name = "#{region}-nmap-results.#{file_type}"
    # copies files back to container and gives them a proper name
    scan_results = `#{SSH_COMMAND} centos@#{NMAP_INSTANCE_ADDRESS} 'cd /home/centos/scans/ && cat output.#{file_type}' > #{__dir__}/output/#{file_name}`
    check_exit_status($CHILD_STATUS.exitstatus, scan_results)
  end
rescue StandardError => e
  error_msg = "There is an issue with ssh or nmap:\n"
  error_msg += "#{scan_results}\n"
  error_msg += e.to_s
  LOGGER.warn(error_msg)
  LOGGER.close
  abort
end

#### MAIN ####
def main
  puts "#{__FILE__} is starting"

  puts 'nmap-port-scan.rb takes a few minutes to run, be patient...'
  puts

  # gather up active ip addresses from todays describe-addresses
  active_addresses = get_todays_ip_list

  # takes master-scannable-instances.json output file of describe-addresses.rb
  # pulls out the list of public ips from each region and runs nmap on that list
  # one region at a time
  use_ec2_addresses_hash(@options[:json_path]).each do |region, address_blob|
    # list to hold all addresses of a region
    ec2_addresses_list = grab_scannable_instances(address_blob, active_addresses)

    # scan the region using the list of addresses
    scan_ports(region, ec2_addresses_list) if ec2_addresses_list != []
  end
  puts "#{__FILE__} has finished"
end

main if $PROGRAM_NAME == __FILE__
