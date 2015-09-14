#
# Author:: Prabhu Das (<prabhu.das@clogeny.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
#

require 'chef/knife/cloud/ec2_service_options'
require 'chef/knife/cloud/ec2_service'
require 'pry'
class Chef
  class Knife
    class Cloud
      module Ec2Helpers

        def create_service_instance
          Ec2Service.new
        end

        def validate!
          errors = []
          unless locate_config_value(:use_iam_profile)
            unless Chef::Config[:knife][:aws_credential_file].nil?
              unless (Chef::Config[:knife].keys & [:aws_access_key_id, :aws_secret_access_key]).empty?
                errors << "Either provide a credentials file or the access key and secret keys but not both."
              end

              # File format:
              # AWSAccessKeyId=somethingsomethingdarkside
              # AWSSecretKey=somethingsomethingcomplete
              #               OR
              # aws_access_key_id = somethingsomethingdarkside
              # aws_secret_access_key = somethingsomethingdarkside
              aws_creds = ini_parse(File.read(Chef::Config[:knife][:aws_credential_file]))
              profile = Chef::Config[:knife][:aws_profile] || 'default'
              entries = aws_creds.values.first.has_key?("AWSAccessKeyId") ? aws_creds.values.first : aws_creds[profile]

              Chef::Config[:knife][:aws_access_key_id] = entries['AWSAccessKeyId'] || entries['aws_access_key_id']
              Chef::Config[:knife][:aws_secret_access_key] = entries['AWSSecretKey'] || entries['aws_secret_access_key']
              error_message = ""
              raise CloudExceptions::ValidationError, error_message if errors.each{|e| ui.error(e); error_message = "#{error_message} #{e}."}.any?
            end
            super(:aws_access_key_id, :aws_secret_access_key)
          end
        end

        def iam_name_from_profile(profile)
          # The IAM profile object only contains the name as part of the arn
          name = profile['arn'].split('/')[-1] if profile && profile.key?('arn')
          name ||= ''
        end

        def ini_parse(file)
          current_section = {}
          map = {}
          file.each_line do |line|
             line = line.split(/^|\s;/).first # remove comments
             section = line.match(/^\s*\[([^\[\]]+)\]\s*$/) unless line.nil?
             if section
               current_section = section[1]
               binding.pry
             elsif current_section
               item = line.match(/^\s*(.+?)\s*=\s*(.+?)\s*$/) unless line.nil?
               binding.pry
               if item
                 map[current_section] ||= {}
                 map[current_section][item[1]] = item[2]
                 binding.pry
               end
             end
          end
          map
        end
      end
    end
  end
end
