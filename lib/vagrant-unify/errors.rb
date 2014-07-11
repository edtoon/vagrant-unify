require "vagrant"

module Vagrant
  module Errors
    class UnifyConfigError < VagrantError
      error_key(:config_error, "vagrant_unify.errors")
    end
    class UnifyError < VagrantError
      error_key(:unify_error, "vagrant_unify.errors")
    end
  end
end
