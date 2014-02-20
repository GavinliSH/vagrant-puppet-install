#
# Copyright (c) 2013, Seth Chisamore
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

begin
  require "vagrant"
rescue LoadError
  raise "The vagrant-puppet-install plugin must be run within Vagrant."
end

# This is a sanity check to make sure no one is attempting to install
# this into an early Vagrant version.
if Vagrant::VERSION < "1.1.0"
  raise "The vagrant-puppet-install plugin is only compatible with Vagrant 1.1+"
end

if Vagrant::VERSION < "1.3.5"
  raise "The vagrant-puppet-install plugin is only compatible with Vagrant 1.3.5 <= right now.\n See https://github.com/patcon/vagrant-puppet-install/issues/5 for details"
end

module VagrantPlugins
  module PuppetInstall
    # @author Seth Chisamore <schisamo@opscode.com>
    class Plugin < Vagrant.plugin("2")
      name "Puppet Install"
      description <<-DESC
      This plugin ensures the desired version of Puppet is installed
      via the Puppet Labs package repos.
      DESC

      def self.provision(hook)

        hook.after(Vagrant::Action::Builtin::Provision, Action.install_puppet)

        # BEGIN workaround
        #
        # Currently hooks attached to {Vagrant::Action::Builtin::Provision} are
        # not wired into the middleware return path. My current workaround is to
        # fire after anything boot related which wedges in right before the
        # actual real run of the provisioner.

        hook.after(VagrantPlugins::ProviderVirtualBox::Action::Boot, Action.install_puppet)

        if VagrantPlugins.const_defined?("AWS")
          hook.after(VagrantPlugins::AWS::Action::RunInstance, Action.install_puppet)
        end

        if VagrantPlugins.const_defined?("Rackspace")
          # The `VagrantPlugins::Rackspace` module is missing the autoload for
          # `VagrantPlugins::Rackspace::Action` so we need to ensure it is
          # loaded before accessing the module in the after hook below.
          require 'vagrant-rackspace/action'
          hook.after(VagrantPlugins::Rackspace::Action::CreateServer, Action.install_puppet)
        end

        # END workaround
      end

      action_hook(:install_puppet, :machine_action_up, &method(:provision))
      action_hook(:install_puppet, :machine_action_provision, &method(:provision))

      config(:puppet_install) do
        require_relative "config"
        Config
      end
    end
  end
end
