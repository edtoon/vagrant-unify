require "optparse"
require "log4r"
require "vagrant"

require_relative "helper"

module VagrantPlugins
  module Unify
    class Command < Vagrant.plugin("2", :command)
      def self.synopsis
        I18n.t("vagrant_unify.push.synopsis")
      end

      def execute
        params = OptionParser.new do |o|
          o.banner = "Usage: vagrant unify-push [vm-name]"
          o.separator ""
        end

        argv = parse_options(params)
        return if !argv

        error = false
        with_target_vms do |machine|
          if !machine.communicate.ready?
            machine.ui.error(I18n.t("vagrant.rsync_communicator_not_ready"))
            error = true
            next
          end

          machine.config.unify.folders.each { |folder|
            local_path  = folder.fetch(0, nil)
            remote_path = folder.fetch(1, nil)
            opts        = folder.fetch(2, {})

            raise Vagrant::Errors::UnifyConfigError, :err => I18n.t("vagrant_unify.config.local_path_required") if local_path.nil? or local_path.empty?
            raise Vagrant::Errors::UnifyConfigError, :err => I18n.t("vagrant_unify.config.remote_path_required") if remote_path.nil? or remote_path.empty?

            UnifyHelper.rsync_single(:push, machine, local_path, remote_path, opts)
          }
        end

        return error ? 1 : 0
      end
    end
  end
end
