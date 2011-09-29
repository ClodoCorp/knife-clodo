require 'chef/knife/clodo_base'

class Chef
  class Knife
    class ClodoServerStart < Knife

      include Knife::ClodoBase

      banner "knife clodo server start (options)"

      option :server,
      :long => "--server ID",
      :description => "The ID of the server",
      :proc => Proc.new { |f| Chef::Config[:knife][:server_id] = f.to_i }

      option :all,
      :long => "--all",
      :description => "Start all the servers that not in \"is_running\" state."

      def run
        $stdout.sync = true

        if config[:all] then

          servers = connection.servers.all.select {|s| case s.state when 'is_running' then false when 'is_request' then false else true end }

          servers.each do |server|
            connection.start_server(server.id)
          end

        elsif Chef::Config[:knife][:server_id] then

          connection.start_server(Chef::Config[:knife][:server_id])

        end

      end

    end
  end
end
