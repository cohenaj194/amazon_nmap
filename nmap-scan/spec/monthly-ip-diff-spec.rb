#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require_relative '../monthly-ip-diff'
require_relative '../shared-functions'

describe 'ip_list_from_hash' do
  before :all do
    wd = File.dirname(__FILE__)
    fixtures = File.join(wd, 'fixtures')

    @ec2_addresses_hash = use_ec2_addresses_hash(File.join(fixtures, 'region_scannable_instances.json'))
    @monthly_ip_list = JSON.parse(File.read(File.join(fixtures, 'monthly_ip_list.json')))
  end

  it 'filters out ip addresses from scannable_instances.json' do
    monthly_ip_list = ip_list_from_hash(@ec2_addresses_hash)
    expect(monthly_ip_list).to eq(@monthly_ip_list)
  end
end

describe 'create_ip_diff' do
  before :all do
    wd = File.dirname(__FILE__)
    fixtures = File.join(wd, 'fixtures')

    @current = ip_list_from_hash(use_ec2_addresses_hash(File.join(fixtures, 'region_scannable_instances.json')))
    @master = ip_list_from_hash(use_ec2_addresses_hash(File.join(fixtures, 'master_scannable_instances.json')))
    @monthly_ip_diff = JSON.parse(File.read(File.join(fixtures, 'monthly_ip_diff.json')))
  end

  it 'creates a diff of ip addresses' do
    monthly_ip_diff = create_ip_diff(@current, @master)
    expect(monthly_ip_diff).to eq(@monthly_ip_diff)
  end
end
