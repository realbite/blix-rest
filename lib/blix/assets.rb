require 'blix/assets/asset_manager'

# add the asset_path method to the Controller if it is being used.
if defined? Blix::Rest
  module Blix
    module Rest
      class Controller
        def asset_path(partial_path)
          if mode_production?
            asset_name = File.basename(partial_path)
            dir_name   = File.dirname(partial_path)
            full_path( File.join(dir_name, AssetManager.get_asset_name(asset_name)))
          else
            full_path(partial_path)
          end
        end
      end
    end
  end
end