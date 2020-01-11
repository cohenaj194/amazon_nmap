#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'optparse'

@options = {
  target: 'vagrant',
  config: 'ci/foobar.yml',
  local_secrets: 'path/to/file',
  extra_params: {}
}

OptionParser.new do |opts|
  opts.on('-c', '--config ci/foobar.yml', 'path to ci file') { |c| @options[:config] = c }
  opts.on('-t', '--target fly_target', 'target concourse server') { |t| @options[:target] = t }
  opts.on('--extra-params path/to/file.json', 'path to extra params file') { |e| @options[:extra_params] = JSON.parse(File.read(e)) }
  opts.banner = <<~EOF

    Use:
      ./fly-execute.rb --config ci/foobar.yml --target vagrant

    Make sure that all needed environmental variables are declared in the params block of your ci/ file.
    Any other params not stored in chef vault secrets need to be declared in the cli or set in a file with the flag --extra-params path/to/file.json
  EOF
end.parse!

@options[:extra_params].each do |k, v|
  ENV[k] = v.to_s
end

exec(ENV, 'fly', 'execute', '-t', @options[:target], '--config', @options[:config], '-i', 'amazon-nmap=.')
