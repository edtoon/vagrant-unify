# Vagrant Unify Plugin

This is a [Vagrant](http://www.vagrantup.com) 1.5+ plugin liberally copy-and-paste'd from
the [vagrant-unison](https://github.com/mrdavidlaing/vagrant-unison) plugin and
Vagrant's own rsync plugin. It allows you to configure a set of folders to synchronize
with Unison or RSync but without the on-startup and automatic sync features of Vagrant's
synchronized folders and the Unison plugin.

**NOTE:** This plugin requires Vagrant 1.5+.

**NOTE:** In order to use the unify-sync command the [Unison](http://www.cis.upenn.edu/~bcpierce/unison/)
application must be installed on both the host and guest machines and available on the PATH as `unison`.

## Usage

Install using standard Vagrant 1.1+ plugin installation methods. 
```
$ vagrant plugin install vagrant-unify
```
After installing, edit your Vagrantfile and add a configuration directive similar to the below:
```
Vagrant.configure("2") do |config|
  config.vm.box = "dummy"
  config.unify.unify_folder "/home/myuser/project1", "/opt/project1"
  config.unify.unify_folder "/home/myuser/git/project2", "/opt/project2", exclude: ".git*"
end
```

## Syncing folders

Run `vagrant unify-pull` to rsync files from the guest to your local host.

Run `vagrant unify-push` to rsync files from your local host to the guest.

Run `vagrant unify-sync` to Unison files between your local host and the guest.
