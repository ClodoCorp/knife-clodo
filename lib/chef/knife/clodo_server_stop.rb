require 'chef/knife/clodo_base'

class Chef
  class Knife
    class ClodoServerStop < Knife

      include Knife::ClodoBase

      banner "knife clodo server stop (options)"

      option :server,
      :long => "--server ID",
      :description => "The ID of the server",
      :proc => Proc.new { |f| Chef::Config[:knife][:server_id] = f.to_i },

      def run
        $stdout.sync = true

        connection.stop_server(Chef::Config[:knife][:server_id])

      end

    end
  end
end
