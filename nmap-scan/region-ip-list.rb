#!/usr/bin/env ruby
# frozen_string_literal: true

# so this should produce the list-of-ips.txt for a single region
# that way we can get each regions ip lists out of scannable-instances.json per region
# then every region can run at the same time to create the nmap output files in different jobs

require_relative 'shared-functions'

@options = {
  json_path: ARGV[0] || "output/scannable-instances.json"
}

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

def main
  puts "#{__FILE__} is starting"

  puts 'nmap-port-scan.rb takes a few minutes to run, be patient...'
  puts

  # gather up active ip addresses from todays describe-addresses
  active_addresses = todays_ip_list

  # takes master-scannable-instances.json output file of describe-addresses.rb
  # pulls out the list of public ips from each region and runs nmap on that list
  # one region at a time
  address_blob = use_ec2_addresses_hash(@options[:json_path])[ENV['REGION']]

  # list to hold all addresses of a region
  ec2_addresses_list = grab_scannable_instances(address_blob, active_addresses)

  # write the regions IP addresses to a file
  `'#{ec2_addresses_list.join("\n")}' > list-of-ips.txt`

  puts "#{__FILE__} has finished"
end

main if $PROGRAM_NAME == __FILE__
