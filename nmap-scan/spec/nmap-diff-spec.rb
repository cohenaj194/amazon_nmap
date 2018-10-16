#!/usr/bin/env ruby

require 'json'
require_relative '../nmap-diff'
require_relative '../shared-functions'

describe 'diff_open_port_check' do
  before :all do
    wd = File.dirname(__FILE__)
    fixtures = File.join(wd, 'fixtures')

    @old_gnmap = JSON.parse(File.read(File.join(fixtures, 'old_gnmap.json')))
    @new_gnmap = JSON.parse(File.read(File.join(fixtures, 'new_gnmap.json')))
    @diff = JSON.parse(File.read(File.join(fixtures, 'diff.json')))
  end

  it 'shows the port delta for the list of hosts' do
    diff = diff_open_port_check(@old_gnmap, @new_gnmap, true)
    expect(diff).to eq(@diff)
  end
end

describe 'common_open_port_check' do
  before :all do
    wd = File.dirname(__FILE__)
    fixtures = File.join(wd, 'fixtures')

    @new_gnmap = JSON.parse(File.read(File.join(fixtures, 'new_gnmap.json')))
    @common = JSON.parse(File.read(File.join(fixtures, 'common.json')))
  end

  it 'shows the port delta for the list of hosts' do
    common = common_open_port_check(@new_gnmap, true)
    expect(common).to eq(@common)
  end
end
