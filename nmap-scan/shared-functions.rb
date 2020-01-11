#!/usr/bin/env ruby
# frozen_string_literal: true

require 'logger'
require 'aws-sdk'
require 'json'
require 'optparse'
require 'csv'

# creating LOGGER
LOGGER = Logger.new(STDERR)

def create_ec2_client(access, secret, region)
  Aws::EC2::Client.new(
    region: region,
    access_key_id: access,
    secret_access_key: secret
  )
end

# returns array of aws regions
def aws_regions_list(access, secret)
  create_ec2_client(access, secret, 'us-west-2').describe_regions.regions.map { |record| record['region_name'] }
end

def create_s3_resource(access, secret)
  Aws::S3::Resource.new(
    region: 'us-west-2',
    access_key_id: access,
    secret_access_key: secret
  )
end

def create_s3_client(_access, _secret)
  Aws::S3::Client.new(
    region: 'us-west-2',
    access_key_id: @options[:access],
    secret_access_key: @options[:secret]
  )
end

# reads the static ip json file master-scannable-instances.json file ./describe-addresses.rb creates
def use_ec2_addresses_hash(json_file)
  JSON.parse(File.read(json_file))
rescue StandardError => e
  error_msg = "Cannot read file #{json_file} or the file does not exist.\n"
  error_msg += "Try running download-static-ip-list.rb and/or describe-addresses.rb to download this file.\n"
  error_msg += e.to_s
  LOGGER.info(error_msg)
  LOGGER.close
  abort
end

# creates a list of todays active public ip addresses from all regions
# using the scannable-instances.csv file
def get_todays_ip_list
  # gather up active ip addresses from todays describe-addresses
  active_addresses = []
  CSV.foreach('output/scannable-instances.csv', headers: true) do |row|
    active_addresses.push(row.to_hash['public_ip_address'])
  end
  active_addresses
end

# creates a list of todays public ip addresses from all regions
# using the hash from a scannable-instances.json, master-scannable-instances.json or all-instances.json file
def get_ip_list_from_hash(ec2_addresses_hash)
  # list to hold all addresses of an account
  ec2_addresses_list = []
  ec2_addresses_hash.each do |_region, address_blob|
    address_blob.each do |address|
      # gathers all ip addresses for a region and pushes all of them to ec2_addresses_list
      ec2_addresses_list.push(address['public_ip_address'])
    end
  end
  ec2_addresses_list
end
