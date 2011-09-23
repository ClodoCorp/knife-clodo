require 'chef/knife/rackspace_base'

class Chef
  class Knife
    class ClodoServerList < Knife

      include Knife::ClodoBase

      banner "knife clodo server list (options)"

      def run
        $stdout.sync = true

        server_list = [
                       ui.color('ID', :bold),
                       ui.color('Public IP', :bold),
                       ui.color('Image', :bold),
                       ui.color('Name', :bold),
                       ui.color('VNC', :bold),
                       ui.color('VNC pass', :bold),
                       ui.color('State', :bold)
                      ]

        connection.servers.each do |server|
          server_list << server.id.to_s
          server_list << server.public_ip_address?server.public_ip_address:""
          server_list << server.image_id
          server_list << server.name
          server_list << server.vps_vnc
          server_list << server.vps_vnc_pass
          server_list << case server.state.downcase
                         when 'is_suspended'
                           ui.color(server.state.downcase, :red)
                         when 'is_disabled', 'is_request'
                           ui.color(server.state.downcase, :lightgrey)
                         when 'is_install'
                           ui.color(server.state.downcase, :yellow)
                         when 'is_running'
                           ui.color(server.state.downcase, :green)
                         end
          puts ui.list(server_list, :columnt_across, 7)
        end
      end
    end
  end
end
