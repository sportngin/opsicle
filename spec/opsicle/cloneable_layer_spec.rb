require "spec_helper"
require "opsicle"
require 'gli'
require "opsicle/user_profile"

module Opsicle
  describe CloneableLayer do
    before do
      @instance1 = double('instance1', :hostname => 'example-hostname-01', :status => 'active',
                                       :ami_id => 'ami_id', :instance_type => 'instance_type',
                                       :agent_version => 'agent_version', :stack_id => 1234567890,
                                       :layer_ids => [12345, 67890], :auto_scaling_type => 'auto_scaling_type',
                                       :os => 'os', :ssh_key_name => 'ssh_key_name',
                                       :availability_zone => 'availability_zone', :virtualization_type => 'virtualization_type',
                                       :subnet_id => 'subnet_id', :architecture => 'architecture',
                                       :root_device_type => 'root_device_type', :install_updates_on_boot => 'install_updates_on_boot',
                                       :ebs_optimized => 'ebs_optimized', :tenancy => 'tenancy')
      @instance2 = double('instance2', :hostname => 'example-hostname-02', :status => 'active',
                                       :ami_id => 'ami_id', :instance_type => 'instance_type',
                                       :agent_version => 'agent_version', :stack_id => 1234567890,
                                       :layer_ids => [12345, 67890], :auto_scaling_type => 'auto_scaling_type',
                                       :os => 'os', :ssh_key_name => 'ssh_key_name',
                                       :availability_zone => 'availability_zone', :virtualization_type => 'virtualization_type',
                                       :subnet_id => 'subnet_id', :architecture => 'architecture',
                                       :root_device_type => 'root_device_type', :install_updates_on_boot => 'install_updates_on_boot',
                                       :ebs_optimized => 'ebs_optimized', :tenancy => 'tenancy')
      @instance3 = double('instance3', :hostname => 'example-hostname-03', :status => 'stopped',
                                       :ami_id => 'ami_id', :instance_type => 'instance_type',
                                       :agent_version => 'agent_version', :stack_id => 1234567890,
                                       :layer_ids => [12345, 67890], :auto_scaling_type => 'auto_scaling_type',
                                       :os => 'os', :ssh_key_name => 'ssh_key_name',
                                       :availability_zone => 'availability_zone', :virtualization_type => 'virtualization_type',
                                       :subnet_id => 'subnet_id', :architecture => 'architecture',
                                       :root_device_type => 'root_device_type', :install_updates_on_boot => 'install_updates_on_boot',
                                       :ebs_optimized => 'ebs_optimized', :tenancy => 'tenancy')
      @instances = double('instances', :instances => [@instance1, @instance2])
      @new_instance = double('new_instance', :instances => [@instance3])
      @opsworks = double('opsworks', :describe_instances => @instances)
    end

    context "#get_cloneable_instances" do
      it "should gather opsworks instances for that layer" do
        layer = CloneableLayer.new('layer-name', 12345, @opsworks, @cli)
        expect(@opsworks).to receive(:describe_instances).and_return(@instances)
        expect(@instances).to receive(:instances)
        layer.get_cloneable_instances
      end

      it "should make a new CloneableInstance for each instance" do
        layer = CloneableLayer.new('layer-name', 12345, @opsworks, @cli)
        expect(CloneableInstance).to receive(:new).twice
        layer.get_cloneable_instances
      end
    end

    context "#add_new_instance" do
      it "should accurately find a new instance via instance_id" do
        layer = CloneableLayer.new('layer-name', 12345, @opsworks, @cli)
        expect(@opsworks).to receive(:describe_instances).and_return(@new_instance)
        expect(@new_instance).to receive(:instances)
        layer.add_new_instance('456-789')
      end

      it "should add the new instance to the instances array" do
        layer = CloneableLayer.new('layer-name', 12345, @opsworks, @cli)
        expect(@opsworks).to receive(:describe_instances).and_return(@new_instance)
        expect(CloneableInstance).to receive(:new).once
        layer.add_new_instance('456-789')
      end
    end
  end
end
