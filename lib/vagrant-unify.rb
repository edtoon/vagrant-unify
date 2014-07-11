require "pathname"

require "vagrant-unify/plugin"
require "vagrant-unify/errors"

module VagrantPlugins
  module Unify
    def self.source_root
      @source_root ||= Pathname.new(File.expand_path("../../", __FILE__))
    end
  end
end
