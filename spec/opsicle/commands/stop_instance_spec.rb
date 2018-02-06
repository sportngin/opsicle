require "spec_helper"
require "opsicle"
require 'gli'
require "opsicle/user_profile"
require "opsicle/aws_instance_manager_helper"

module Opsicle
  describe StopInstance do
    include Opsicle::AwsInstanceManagerHelper

    before do
      @instance1 = double('instance1', :hostname => 'example-hostname-01', :status => 'active',
                                       :ami_id => 'ami_id', :instance_type => 'instance_type',
                                       :agent_version => 'agent_version', :stack_id => 1234567890,
                                       :layer_ids => [12345, 67890], :auto_scaling_type => 'auto_scaling_type',
                                       :os => 'os', :ssh_key_name => 'ssh_key_name',
                                       :availability_zone => 'availability_zone', :virtualization_type => 'virtualization_type',
                                       :subnet_id => 'subnet_id', :architecture => 'architecture',
                                       :root_device_type => 'root_device_type', :install_updates_on_boot => 'install_updates_on_boot',
                                       :ebs_optimized => 'ebs_optimized', :tenancy => 'tenancy', :instance_id => 'some-id', :elastic_ip => nil)
      @instance2 = double('instance2', :hostname => 'example-hostname-02', :status => 'active',
                                       :ami_id => 'ami_id', :instance_type => 'instance_type',
                                       :agent_version => 'agent_version', :stack_id => 1234567890,
                                       :layer_ids => [12345, 67890], :auto_scaling_type => 'auto_scaling_type',
                                       :os => 'os', :ssh_key_name => 'ssh_key_name',
                                       :availability_zone => 'availability_zone', :virtualization_type => 'virtualization_type',
                                       :subnet_id => 'subnet_id', :architecture => 'architecture',
                                       :root_device_type => 'root_device_type', :install_updates_on_boot => 'install_updates_on_boot',
                                       :ebs_optimized => 'ebs_optimized', :tenancy => 'tenancy', :instance_id => 'some-id', :elastic_ip => nil)
      @instances = double('instances', :instances => [@instance1, @instance2])
      @layer1 = double('layer1', :name => 'layer-1', :layer_id => 12345, :instances => [@instance1, @instance2])
      @layer2 = double('layer2', :name => 'layer-2', :layer_id => 67890, :instances => [@instance1, @instance2])
      @layers = double('layers', :layers => [@layer1, @layer2])
      @stack = double('stack', :vpc_id => "vpc-123456", :stoppable_instances => [])
      @stacks = double('stacks', :stacks => [@stack])
      @opsworks = double('opsworks', :describe_instances => @instances, :describe_layers => @layers,
                                     :create_instance => @new_instance, :describe_stacks => @stacks,
                                     :start_instance => @new_instance)
      @ec2 = double('ec2')
      @config = double('config', :opsworks_config => {:stack_id => 1234567890})
      @client = double('client', :config => @config, :opsworks => @opsworks, :ec2 => @ec2)
      allow(Client).to receive(:new).with(:environment).and_return(@client)
      allow(@instances).to receive(:each_with_index)
      allow(@opsworks).to receive(:describe_agent_versions).and_return(@agent_versions)
      allow_any_instance_of(HighLine).to receive(:ask).with("Layer?\n", Integer).and_return(2)
    end

    context "#execute" do
      it "lists all current layers" do
        expect(@opsworks).to receive(:describe_layers)
        StopInstance.new(:environment).execute
      end

      context "#select_deletable_or_stoppable_instances" do
        it "should ask the stack for all stoppable instances" do
          expect(@stack).to receive(:stoppable_instances)
          select_deletable_or_stoppable_instances(@layer, :stop)
        end

        it "should return an empty array" do
          allow(@stack).to receive(:stoppable_instances).and_return([])
          result = select_deletable_or_stoppable_instances(@layer, :stop)
          expect(result).to eq([])
        end

        it "should return an array of 1" do
          allow(@cli).to receive(:ask).and_return("1")
          allow(@stack).to receive(:stoppable_instances).and_return([@instance1])
          result = select_deletable_or_stoppable_instances(@layer, :stop)
          expect(result).to eq([@instance1])
        end
      end

      context "#stop_or_delete" do
        it "should stop or delete" do
          expect(@opsworks).to receive(:stop_instance).and_return(true)
          stop_or_delete([@instance1], :stop)
        end
      end
    end
  end
end
