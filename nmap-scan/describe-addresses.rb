#!/usr/bin/env ruby
require_relative 'shared-functions'

# creates scannable-instances.json

@options = {
  access: ENV['SCAN_AWS_ACCESS_KEY_ID'],
  secret: ENV['SCAN_AWS_SECRET_ACCESS_KEY'],
  all_instances: Array.new,
  ec2_addresses_hash: Hash.new,
}
opt_parser = OptionParser.new do |opts|
  opts.banner = <<-EOF
Description: creates scannable-instances.json, scannable-instances.csv, all-instances.csv and all-instances.json

Takes SCAN_AWS_ACCESS_KEY_ID and SCAN_AWS_SECRET_ACCESS_KEY as the default aws variables.
If you dont want to set these then use the optional cli arguments instead:

Usage: bundle exec ruby #{__FILE__} -a $AWS_ACCESS_KEY_ID -s $AWS_SECRET_ACCESS_KEY
EOF
  opts.on('-a', '--access ACCESS', 'access') { |access| @options[:access] = access }
  opts.on('-s', '--secret SECRET', 'secret') { |secret| @options[:secret] = secret }
end.parse!

def filter_describe_instances_output(ec2_all, region, rspec=false)
  public_ip_list = Array.new

  # places desired info of instance into a list 
  # this list will be turned into a json and csv file
  ec2_all.each do | instances |
    instances[:instances].each do | instance |

      #gathering instance name from instance tags
      instance_name = ""

      # note that many instances in wildwest do not have any tags
      if instance[:tags] != nil
        instance[:tags].each do | tag |
          if tag[:key] == "Name"
            instance_name = tag[:value]
          end
        end
      end

      # only use all_instances outside of rspec
      if !rspec
        @options[:all_instances].push({
            "instance_id" => instance[:instance_id],
            "instance_name" => instance_name,
            "region" => region,
            "public_ip_address" => instance[:public_ip_address],
            "public_dns_name" => instance[:public_dns_name],
            "instance_type" => instance[:instance_type],
            "state" => instance[:state][:name],
        })
      end

      # we are not allowed to scan 'm1.small', 't1.micro' and 't2.nano' instances 
      # see https://aws.amazon.com/security/penetration-testing/ for details
      if ['t1.micro', 't2.nano', 'm1.small'].include? instance[:instance_type]
        puts "filtered out #{instance[:instance_id]} type: #{instance[:instance_type]} region: #{region}"
      elsif instance[:public_ip_address] == nil
        puts "filtered out #{instance[:instance_id]} type: #{instance[:instance_type]} region: #{region}, it has no public ip address"
      else  
        public_ip_list.push({
          "instance_id" => instance[:instance_id],
          "instance_name" => instance_name,
          "region" => region,
          "public_ip_address" => instance[:public_ip_address],
          "public_dns_name" => instance[:public_dns_name],
          "instance_type" => instance[:instance_type],
        })
      end
    end
  end

  return public_ip_list
end

def main
  puts "#{__FILE__} is starting"

  # checks every region for ec2 instances
  aws_regions_list(@options[:access], @options[:secret]).each do |region|

    ec2 = create_ec2_client(@options[:access], @options[:secret], region)

    ec2_all = ec2.describe_instances.to_hash[:reservations]

    @options[:ec2_addresses_hash][region.to_s] = filter_describe_instances_output(ec2_all,region)
  end

  # creating json file contaning scannable instances 
  File.open("./output/scannable-instances.json","w") do |file|
    file.write(@options[:ec2_addresses_hash].to_json)
  end

  # creating csv file contaning scannable instances 
  CSV.open('./output/scannable-instances.csv', "w") do |csv|
    csv << ["instance_id","instance_name","region","public_ip_address","public_dns_name","instance_type"]
    @options[:all_instances].each do | instance |
      # adds instances to the list if 
      #  * they have a public ip address 
      #  * and they are not a 't1.micro', 't2.nano' or 'm1.small'
      if instance["public_ip_address"] != nil && ! ['t1.micro', 't2.nano', 'm1.small'].include?(instance["instance_type"])
        csv << instance.values
      end
    end
  end

  # creating json file contaning all instances
  File.open('./output/all-instances.json',"w") do |file|
    file.write("#{@options[:all_instances].to_json}")
  end

  # creating csv file contaning all instances
  CSV.open('./output/all-instances.csv', "w") do |csv|
    csv << ["instance_id","instance_name","region","public_ip_address","public_dns_name","instance_type","state"]
    @options[:all_instances].each do | instance |
      csv << instance.values
    end
  end
  puts "#{__FILE__} has finished"
end

if $0 == __FILE__
  main
end