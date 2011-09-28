require 'chef/knife/clodo_base'

class Chef
  class Knife
    class ClodoServerDelete < Knife

      include Knife::ClodoBase

      banner "knife clodo server delete (options)"

      option :server,
      :long => "--server ID",
      :description => "The ID of the server",
      :proc => Proc.new { |f| Chef::Config[:knife][:server_id] = f.to_i }

      def run
        $stdout.sync = true

        connection.delete_server(Chef::Config[:knife][:server_id])

      end

    end
  end
end
