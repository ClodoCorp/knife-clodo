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
          :description => "Your clodo.ru API key"

          option :clodo_username,
          :short => "-A USERNAME",
          :long => "--clodo-username USERNAME",
          :description => "Your clodo.ru API username"

          option :clodo_api_auth_url,
          :long => "--clodo-api-auth-url URL",
          :description => "Your clodo.ru API auth url"
        end

        def connection
          @connection ||= Fog::Compute::Clodo.new({
                                                    :clodo_api_key  => locate_config_value 'clodo_api_key',
                                                    :clodo_username => locate_config_value 'clodo_username',
                                                    :clodo_auth_url => locate_config_value 'clodo_api_auth_url' || 'api.clodo.ru'})
        end

        def locate_config_value(key)
          key = key.to_sym
          config[key] || Chef::Config[:knife][key]
        end

        def public_dns_name(server)
          @public_dns_name ||= begin
                                 Resolv.getname(server.public_ip_address)
                               rescue
                                 "#{server.public_ip_address.gsub('.','-')}.clodo.ru"
                               end
        end

      end

    end
  end
end
