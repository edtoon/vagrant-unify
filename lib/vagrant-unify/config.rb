require "vagrant"

module VagrantPlugins
  module Unify
    class Config < Vagrant.plugin("2", :config)
      attr_accessor :folders

      def initialize(region_specific=false)
        @folders = []
      end

      def unify_folder(local_path, remote_path, opts = {})
        @folders << [local_path, remote_path, opts]
      end
    end
  end
end
