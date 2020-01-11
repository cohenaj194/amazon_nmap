#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require_relative '../nmap-port-scan'
require_relative '../shared-functions'

describe 'grab_scannable_instances' do
  before :all do
    wd = File.dirname(__FILE__)
    fixtures = File.join(wd, 'fixtures')

    @master_scannable_instances = JSON.parse(File.read(File.join(fixtures, 'scannable_instances.json')))
    @active_ip_list = JSON.parse(File.read(File.join(fixtures, 'active_ip_list.json')))
    @port_scan_ip_list = JSON.parse(File.read(File.join(fixtures, 'port_scan_ip_list.json')))
  end

  it 'get public ips from a blob of info on a single aws region' do
    port_scan_ip_list = grab_scannable_instances(@master_scannable_instances, @active_ip_list)
    expect(port_scan_ip_list).to eq(@port_scan_ip_list)
  end
end
