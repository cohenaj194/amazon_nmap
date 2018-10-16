#!/usr/bin/env ruby

require 'json'
require_relative '../describe-addresses'
require_relative '../shared-functions'

describe 'filter_describe_instances_output' do
  before :all do
    wd = File.dirname(__FILE__)
    fixtures = File.join(wd, 'fixtures')

    @raw_ec2 = JSON.parse(File.read(File.join(fixtures, 'raw_ec2.json')), opts = {symbolize_names: true})
    @scannable_instances = JSON.parse(File.read(File.join(fixtures, 'scannable_instances.json')))
  end

  it 'filters out instances from the aws-sdk describe-instances hash' do
    scannable_instances = filter_describe_instances_output(@raw_ec2, 'us-west-2', true)
    expect(scannable_instances).to eq(@scannable_instances)
  end
end

