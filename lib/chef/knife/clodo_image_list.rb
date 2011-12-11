require 'chef/knife/clodo_base'

class Chef
  class Knife
    class ClodoImageList < Knife

      include Knife::ClodoBase

      banner "knife clodo image list (options)"

      def run
        $stdout.sync = true

        image_list = [
                      ui.color('ID', :bold),
                      ui.color('Name', :bold),
                      ui.color('Type', :bold)
                     ]

        connection.images.each do |image|
          image_list << image.id.to_s
          image_list << image.name
          image_list << image.vps_type
        end
        puts ui.list(image_list, :columns_across, 3)
      end
    end
  end
end
