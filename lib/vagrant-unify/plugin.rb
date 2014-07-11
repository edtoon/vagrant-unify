begin
  require "vagrant"
rescue LoadError
  raise "The vagrant-unify plugin must be run within Vagrant."
end

if Vagrant::VERSION < "1.5"
  raise "The vagrant-unify plugin is only compatible with Vagrant 1.5+"
end

module VagrantPlugins
  module Unify
    class Plugin < Vagrant.plugin("2")
      name "Unify"
      description = <<-DESC
      This plugin syncs files between a local folder and
      your Vagrant machine via either Unison or RSync
      DESC

      config "unify" do
        require_relative "config"
        Config
      end

      command "unify-pull" do
        setup_logging
        setup_i18n

        require_relative "command-pull"
        Command
      end

      command "unify-push" do
        setup_logging
        setup_i18n

        require_relative "command-push"
        Command
      end

      command "unify-sync" do
        setup_logging
        setup_i18n

        require_relative "command-sync"
        Command
      end

      def self.setup_i18n
        I18n.load_path << File.expand_path("locales/en.yml", Unify.source_root)
        I18n.reload!
      end

      def self.setup_logging
        require "log4r"

        level = nil
        begin
          level = Log4r.const_get(ENV["VAGRANT_LOG"].upcase)
        rescue NameError
          level = nil
        end

        level = nil if !level.is_a?(Integer)

        if level
          logger = Log4r::Logger.new("vagrant_unify")
          logger.outputters = Log4r::Outputter.stderr
          logger.level = level
          logger = nil
        end
      end
    end
  end
end
