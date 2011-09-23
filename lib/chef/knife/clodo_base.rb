require 'chef/knife'

class Chef
  class Knife
    module ClodoBase

      # I don't know what this means, so just copy it from Rackspace
      def self.included(includer)
        includer.class_eval do

          deps do
            require 'fog'
            require 'net/ssh/multi'
            require 'readline'
            require 'chef/json_compat'
          end

          option :clodo_api_key,
          :short => "-K KEY",
          :long => "--clodo-api-key KEY",
          :description => "Your clodo.ru API key",
          :proc => Proc.new { |key| Chef::Config[:knife][:clodo_api_key] = key }

          option :clodo_username,
          :short => "-A USERNAME",
          :long => "--clodo-username USERNAME",
          :description => "Your clodo.ru API username",
          :proc => Proc.new { |username| Chef::Config[:knife][:clodo_username] = username }

          option :clodo_api_auth_url,
          :long => "--clodo-api-auth-url URL",
          :description => "Your clodo.ru API auth url",
          :default => "api.clodo.ru",
          :proc => Proc.new { |url| Chef::Config[:knife][:clodo_api_auth_url] = url }
        end

        def connection
          @connection ||= Fog::Compute::Clodo.new({
                                                    :clodo_api_key => Chef::Config[:knife][:clodo_api_key],
                                                    :clodo_username => (Chef::Config[:knife][:clodo_username] || Chef::Config[:knife][:clodo_api_username]),
                                                    :clodo_auth_url => Chef::Config[:knife][:clodo_api_auth_url] || config[:clodo_api_auth_url]})
        end

        def locate_config_value(key)
          key = key.to_sym
          Chef::Config[:knife][key] || config[key]
        end

        def public_dns_name(server)
          @public_dns_name ||= begin
                                 Resolv.getname(server.addresses["public"][0])
                               rescue
                                 "#{server.addresses["public"][0].gsub('.','-')}.clodo.ru"
                               end
        end

      end

    end
  end
end
