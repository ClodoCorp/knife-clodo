require 'chef/knife/clodo_base'

class Chef
  class Knife
    class ClodoServerCreate < Knife

      include Knife::ClodoBase

      deps do
        require 'fog'
        require 'readline'
        require 'chef/json_compat'
        require 'chef/knife/bootstrap'
        Chef::Knife::Bootstrap.load_deps
      end

      banner "knife clodo server create (options)"

      option :image,
      :short => "-I IMAGE",
      :long => "--image IMAGE",
      :description => "The image of server; default is 541 (Debian 6 amd64 Scale)",
      :proc => Proc.new { |f| Chef::Config[:knife][:image] = f.to_i },
      :default => 541

      option :server_name,
      :short => "-N NAME",
      :long => "--server-name NAME",
      :description => "The title for your server"

      option :server_type,
      :long => "--server-type TYPE",
      :description => "Type of the server - static or scale (default scale)",
      :proc => Proc.new {|f| Chef::Config[:knife][:server_type] = f=="static"?"VirtualServer":"ScaleServer"},
      :default => "ScaleServer"

      option :server_memory,
      :long => "--server-memory MB",
      :description => "For static server is an amount of memory in megabytes, for scale server is a low limit in megabytes. (default is 512MB)",
      :proc => Proc.new {|m| Chef::Config[:knife][:server_memory] = m.to_i},
      :default => 512

      option :server_memory_max,
      :long => "--server-memory-max MB",
      :description => "For static server is ignored, for scale server is a high limit in megabytes. (default is 4096MB)",
      :proc => Proc.new {|m| Chef::Config[:knife][:server_memory_max] = m.to_i},
      :default => 4096

      option :server_disk,
      :long => "--server-disk GB",
      :description => "Server's disk size in gigabytes. (default 10GB)",
      :proc => Proc.new {|d| Chef::Config[:knife][:server_disk] = d.to_i},
      :default => 10

      option :server_support_level,
      :long => "--server-support-level LEVEL",
      :description => "Support level for this server. Default is always 1. You can also choose from 2 and 3",
      :proc => Proc.new {|s| Chef::Config[:knife][:server_support_level] = s.to_i},
      :default => 1

      option :chef_node_name,
      :long => "--node-name NAME",
      :description => "The Chef node name for your new node"

      option :ssh_user,
      :short => "-x USERNAME",
      :long => "--ssh-user USERNAME",
      :description => "The ssh username; default is 'root'",
      :default => "root"

      option :ssh_password,
      :short => "-P PASSWORD",
      :long => "--ssh-password PASSWORD",
      :description => "The ssh password"

      option :identity_file,
      :short => "-i IDENTITY_FILE",
      :long => "--identity-file IDENTITY_FILE",
      :description => "The SSH identity file used for authentication"

      option :prerelease,
      :long => "--prerelease",
      :description => "Install the pre-release chef gems"

      option :bootstrap_version,
      :long => "--bootstrap-version VERSION",
      :description => "The version of Chef to install",
      :proc => Proc.new { |v| Chef::Config[:knife][:bootstrap_version] = v }

      option :bootstrap_delay,
      :long => "--bootstrap-delay SEC",
      :description => "Delay in seconds between SSH is available and bootstrap begin. (Default is 15 sec.)",
      :default => 15

      option :prerelease,
      :long => "--prerelease",
      :description => "Install the pre-release chef gems"

      option :distro,
      :short => "-d DISTRO",
      :long => "--distro DISTRO",
      :description => "Bootstrap a distro using a template; default is 'debian6apt'"

      option :template_file,
      :long => "--template-file TEMPLATE",
      :description => "Full path to location of template to use",
      :default => false

      option :run_list,
      :short => "-r RUN_LIST",
      :long => "--run-list RUN_LIST",
      :description => "Comma separated list of roles/recipes to apply",
      :proc => lambda { |o| o.split(/[\s,]+/) },
      :default => []

      def tcp_test_ssh(hostname)
        tcp_socket = TCPSocket.new(hostname, 22)
        readable = IO.select([tcp_socket], nil, nil, 5)
        if readable
          Chef::Log.debug("sshd accepting connections on #{hostname}, banner is #{tcp_socket.gets}")
          yield
          true
        else
          false
        end
      rescue Errno::ETIMEDOUT
        false
      rescue Errno::EPERM
        false
      rescue Errno::ECONNREFUSED
        sleep 2
        false
      rescue Errno::EHOSTUNREACH
        sleep 2
        false
      ensure
        tcp_socket && tcp_socket.close
      end


      def run
        $stdout.sync = true

        unless Chef::Config[:knife][:image]
          ui.error("You have not provided a valid image value.  Please note the short option for this value recently changed from '-i' to '-I'.")
          exit 1
        end

        options = {
          :vps_type => Chef::Config[:knife][:server_type] || config[:server_type],
          :vps_memory => Chef::Config[:knife][:server_memory] || config[:server_memory],
          :vps_memory_max => Chef::Config[:knife][:server_memory_max] || config[:server_memory_max],
          :vps_hdd => Chef::Config[:knife][:server_disk] || config[:server_disk],
          :vps_admin => Chef::Config[:knife][:server_support_level] || config[:server_support_level],
          :vps_os => Chef::Config[:knife][:image]
        }

        options[:name] = config[:server_name] if config[:server_name]

        server = connection.servers.create(options)

        puts "#{ui.color("ID", :cyan)}: #{server.id}"
        puts "#{ui.color("Name", :cyan)}: #{server.name}"
        puts "#{ui.color("Image", :cyan)}: #{server.image}"
        puts "#{ui.color("IP", :cyan)}: #{server.public_ip_address}"
        puts "#{ui.color("root password", :red)}: #{server.password}"

        print "\n#{ui.color("Waiting server", :magenta)}"

        # wait for it to be ready to do stuff
        server.wait_for { print "."; ready? }

        puts("\n")

        puts "#{ui.color("Public DNS Name", :cyan)}: #{public_dns_name(server)}"
        puts "#{ui.color("Public IP Address", :cyan)}: #{server.public_ip_address}"
        puts "#{ui.color("Password", :cyan)}: #{server.password}"

        print "\n#{ui.color("Waiting for sshd", :magenta)}"

        print(".") until tcp_test_ssh(server.public_ip_address) { sleep @initial_sleep_delay ||= config[:bootstrap_delay].to_i; puts("done") }

	if File::exists? "#{ENV['HOME']}/.ssh/id_rsa.pub"
	        server.public_key_path = "#{ENV['HOME']}/.ssh/id_rsa.pub" 
	        server.setup({:password => server.password})
	end

        bootstrap_for_node(server).run if Chef::Config[:knife][:distro] || Chef::Config[:knife][:template_file]

        puts "\n"
        puts "#{ui.color("Instance ID", :cyan)}: #{server.id}"
        puts "#{ui.color("Name", :cyan)}: #{server.name}"
        puts "#{ui.color("Image", :cyan)}: #{server.image}"
        puts "#{ui.color("Public DNS Name", :cyan)}: #{public_dns_name(server)}"
        puts "#{ui.color("Public IP Address", :cyan)}: #{server.public_ip_address}"
        puts "#{ui.color("Password", :cyan)}: #{server.password}"
        puts "#{ui.color("Environment", :cyan)}: #{config[:environment] || '_default'}"
        puts "#{ui.color("Run List", :cyan)}: #{config[:run_list].join(', ')}"
      end

      def bootstrap_for_node(server)
        bootstrap = Chef::Knife::Bootstrap.new
        bootstrap.name_args = [public_dns_name(server)]
        bootstrap.config[:run_list] = config[:run_list]
        bootstrap.config[:ssh_user] = config[:ssh_user] || "root"
        bootstrap.config[:ssh_password] = server.password
        bootstrap.config[:identity_file] = config[:identity_file]
        bootstrap.config[:chef_node_name] = config[:chef_node_name] || server.id
        bootstrap.config[:prerelease] = config[:prerelease]
        bootstrap.config[:bootstrap_version] = locate_config_value(:bootstrap_version)
        # bootstrap will run as root...sudo (by default) also messes up Ohai on CentOS boxes
        bootstrap.config[:use_sudo] = true unless config[:ssh_user] == 'root'
        bootstrap.config[:environment] = config[:environment]
        bootstrap
      end

    end
  end
end
