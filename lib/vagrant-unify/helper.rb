require "fileutils"
require "vagrant/util/platform"
require "vagrant/util/subprocess"

module VagrantPlugins
  module Unify
    class UnifyHelper
      def self.init_ops(machine, local_path, remote_path, opts)
        opts[:hostpath] ||= local_path
        opts[:guestpath] ||= remote_path
        opts[:owner] ||= machine.ssh_info[:username]
        opts[:group] ||= machine.ssh_info[:username]
        return opts
      end

      def self.init_paths(machine, local_path, remote_path, cygwinify = false)
        guestpath = remote_path
        hostpath  = File.expand_path(local_path, machine.env.root_path)
        hostpath  = Vagrant::Util::Platform.fs_real_path(hostpath).to_s

        if cygwinify and Vagrant::Util::Platform.windows?
          hostpath = Vagrant::Util::Platform.cygwin_path(hostpath)
        end

        if !guestpath.end_with?("/")
          guestpath += "/"
        end

        if !hostpath.end_with?("/")
          hostpath += "/"
        end

        return [hostpath, guestpath]
      end

      def self.init_ssh_args(machine)
        ssh_info = machine.ssh_info
        proxy_command = ""

        if ssh_info[:proxy_command]
          proxy_command = "-o ProxyCommand='#{ssh_info[:proxy_command]}' "
        end

        return [
          "-p #{ssh_info[:port]} " +
          proxy_command +
          "-o StrictHostKeyChecking=no " +
          "-o UserKnownHostsFile=/dev/null",
          ssh_info[:private_key_path].map { |p| "-i '#{p}'" },
        ].flatten.join(" ")
      end

      def self.init_excludes(opts)
        excludes = ['.vagrant/', '.DS_Store']
        excludes += Array(opts[:exclude]).map(&:to_s) if opts[:exclude]
        excludes.uniq!
        return excludes
      end

      def self.pre_sync(machine, hostpath, guestpath, opts)
        if machine.guest.capability?(:rsync_pre)
          machine.guest.capability(:rsync_pre, opts)
        else
          machine.communicate.sudo("mkdir -p '#{guestpath}'")
          machine.communicate.sudo("chown #{machine.ssh_info[:username]} '#{guestpath}'")
        end

        FileUtils.mkdir_p(hostpath)
      end

      def self.post_sync(machine, opts)
        if machine.guest.capability?(:rsync_post)
          machine.guest.capability(:rsync_post, opts)
        end
      end

      def self.unison_single(machine, local_path, remote_path, opts)
        opts = init_ops(machine, local_path, remote_path, opts)
        hostpath, guestpath = init_paths(machine, local_path, remote_path)
        ssh_args = init_ssh_args(machine)
        excludes = init_excludes(opts)

        command = [
          "unison", "-batch",
          "-ignore=Name {" + excludes.join(",")  + "}",
          "-sshargs", ssh_args,
          hostpath,
          "ssh://#{machine.ssh_info[:username]}@#{machine.ssh_info[:host]}/#{guestpath}"
        ]

        command_opts = {}
        command_opts[:workdir] = machine.env.root_path.to_s

        command = command + [command_opts]

        machine.ui.info(I18n.t(
          "vagrant_unify.sync.message", guestpath: guestpath, hostpath: hostpath))
        if excludes.length > 1
          machine.ui.info(I18n.t(
            "vagrant_unify.excludes", excludes: excludes.inspect))
        end

        pre_sync(machine, hostpath, guestpath, opts)

        r = Vagrant::Util::Subprocess.execute(*command)
        case r.exit_code
        when 0
          machine.ui.info(I18n.t("vagrant_unify.unison.success_0"))
        when 1
          machine.ui.info(I18n.t("vagrant_unify.unison.success_1"))
        when 2
          machine.ui.info(I18n.t("vagrant_unify.unison.success_2"))
        else
          raise Vagrant::Errors::UnifyError,
            :command => command.inspect,
            :guestpath => guestpath,
            :hostpath => hostpath,
            :stderr => r.stderr
        end

        post_sync(machine, opts)
      end

      def self.rsync_single(direction, machine, local_path, remote_path, opts)
        opts = init_ops(machine, local_path, remote_path, opts)
        hostpath, guestpath = init_paths(machine, local_path, remote_path, true)
        ssh_args = init_ssh_args(machine)
        excludes = init_excludes(opts)

        args = nil
        args = Array(opts[:args]).dup if opts[:args]
        args ||= ["--verbose", "--archive", "--delete", "-z", "--copy-links"]

        if Vagrant::Util::Platform.windows? && !args.any? { |arg| arg.start_with?("--chmod=") }
          args << "--chmod=ugo=rwX"

          args << "--no-perms" if args.include?("--archive") || args.include?("-a")
        end

        args << "--no-owner" unless args.include?("--owner") || args.include?("-o")
        args << "--no-group" unless args.include?("--group") || args.include?("-g")

        if machine.guest.capability?(:rsync_command)
          args << "--rsync-path"<< machine.guest.capability(:rsync_command)
        end

        guest_spec = "#{machine.ssh_info[:username]}@#{machine.ssh_info[:host]}:#{guestpath}"
        from_path = hostpath
        to_path = guest_spec

        if :pull.equal?(direction)
          from_path = guest_spec
          to_path = hostpath
        end

        command = [
          "rsync",
          args,
          "-e", "ssh " + ssh_args,
          excludes.map { |e| ["--exclude", e] },
          from_path,
          to_path,
        ].flatten

        command_opts = {}
        command_opts[:workdir] = machine.env.root_path.to_s

        command = command + [command_opts]

        if :pull.equal?(direction)
          machine.ui.info(I18n.t(
            "vagrant_unify.pull.message", guestpath: guestpath, hostpath: hostpath))
        else
          machine.ui.info(I18n.t(
            "vagrant_unify.push.message", guestpath: guestpath, hostpath: hostpath))
        end
        if excludes.length > 1
          machine.ui.info(I18n.t(
            "vagrant_unify.excludes", excludes: excludes.inspect))
        end

        pre_sync(machine, hostpath, guestpath, opts)

        r = Vagrant::Util::Subprocess.execute(*command)
        if r.exit_code != 0
          raise Vagrant::Errors::UnifyError,
            command: command.inspect,
            guestpath: guestpath,
            hostpath: hostpath,
            stderr: r.stderr
        end

        post_sync(machine, opts)
      end
    end
  end
end
