require 'chef/knife/clodo_base'

class Chef
  class Knife
    class ClodoServerStart < Knife

      include Knife::ClodoBase

      banner "knife clodo server start (options)"

      option :server,
      :long => "--server ID",
      :description => "The ID of the server",
      :proc => Proc.new { |f| Chef::Config[:knife][:server_id] = f.to_i },

      def run
        $stdout.sync = true

        connection.start_server(Chef::Config[:knife][:server_id])

      end

    end
  end
end
