require "spec_helper"
require "opsicle"
require 'gli'
require "opsicle/user_profile"
require "opsicle/aws_instance_manager_helper"

module Opsicle
  describe MoveEip do
    include Opsicle::AwsInstanceManagerHelper

    before do
      @instance1 = double('instance1', :hostname => 'example-hostname-01', :status => 'active',
                                       :ami_id => 'ami_id', :instance_type => 'instance_type',
                                       :agent_version => 'agent_version', :stack_id => 1234567890,
                                       :layer_ids => [12345, 67890], :auto_scaling_type => nil,
                                       :os => 'os', :ssh_key_name => 'ssh_key_name',
                                       :availability_zone => 'availability_zone', :virtualization_type => 'virtualization_type',
                                       :subnet_id => 'subnet_id', :architecture => 'architecture',
                                       :root_device_type => 'root_device_type', :install_updates_on_boot => 'install_updates_on_boot',
                                       :ebs_optimized => 'ebs_optimized', :tenancy => 'tenancy', :instance_id => 'some-id', :elastic_ip => nil)
      @instance2 = double('instance2', :hostname => 'example-hostname-02', :status => 'active',
                                       :ami_id => 'ami_id', :instance_type => 'instance_type',
                                       :agent_version => 'agent_version', :stack_id => 1234567890,
                                       :layer_ids => [12345, 67890], :auto_scaling_type => nil,
                                       :os => 'os', :ssh_key_name => 'ssh_key_name',
                                       :availability_zone => 'availability_zone', :virtualization_type => 'virtualization_type',
                                       :subnet_id => 'subnet_id', :architecture => 'architecture',
                                       :root_device_type => 'root_device_type', :install_updates_on_boot => 'install_updates_on_boot',
                                       :ebs_optimized => 'ebs_optimized', :tenancy => 'tenancy', :instance_id => 'some-id', :elastic_ip => nil)
      @instances = double('instances', :instances => [@instance1, @instance2])
      @layer1 = double('layer1', :name => 'layer-1', :layer_id => 12345, :instances => [@instance1, @instance2])
      @layer2 = double('layer2', :name => 'layer-2', :layer_id => 67890, :instances => [@instance1, @instance2])
      @layers = double('layers', :layers => [@layer1, @layer2])
      @eip = double('eip', :ip => '12.34.56.78', :instance_id => 'some-id')
      @eips = double('eip list', :elastic_ips => [@eip])
      @stack = double('stack', :vpc_id => "vpc-123456", :eips => [@eip])
      @stacks = double('stacks', :stacks => [@stack])
      @opsworks = double('opsworks', :describe_instances => @instances, :describe_layers => @layers,
                                     :create_instance => @new_instance, :describe_stacks => @stacks,
                                     :start_instance => @new_instance)
      @ec2 = double('ec2')
      @config = double('config', :opsworks_config => {:stack_id => 1234567890})
      @client = double('client', :config => @config, :opsworks => @opsworks, :ec2 => @ec2)
      allow(Client).to receive(:new).with(:environment).and_return(@client)
      allow(@instances).to receive(:each_with_index)
      allow(@opsworks).to receive(:describe_elastic_ips).and_return(@eips)
      allow_any_instance_of(HighLine).to receive(:ask).with("Which EIP would you like to move?\n", Integer).and_return(1)
      allow_any_instance_of(HighLine).to receive(:ask).with("What is your target instance?\n", Integer).and_return(1)
      @manageable_stack = ManageableStack.new("1234", @opsworks)
      allow(@manageable_stack).to receive(:transfer_eip)
      allow(@manageable_stack).to receive(:get_eips)
    end

    context "#execute" do
      context "#gather_eip_information" do
        it "should look up all of the EIPs in the stack" do
          allow(@opsworks).to receive(:describe_instances).and_return(@instances)
          allow(@opsworks).to receive(:describe_layers).and_return(@layers)
          expect(@stack).to receive(:eips).and_return([@eip])
          gather_eip_information
        end

        it "should return an array of hashes which represent EIP info" do
          allow(@opsworks).to receive(:describe_instances).and_return(@instances)
          allow(@opsworks).to receive(:describe_layers).and_return(@layers)
          allow(@manageable_stack).to receive(:eips).and_return([@eip])
          result = gather_eip_information
          expect(result).to eq([{eip: @eip, ip_address: @eip.ip, instance_name: "example-hostname-01", layer_id: 12345}])
        end
      end

      context "#ask_which_eip_to_move" do
        before do
          @eip_information = [{eip: @eip, ip_address: @eip.ip, instance_name: "example-hostname-01", layer_id: 12345}]
        end

        it "should ask us which EIP to move" do
          expect(@cli).to receive(:ask).with("Which EIP would you like to move?\n", Integer).and_return(1)
          ask_which_eip_to_move(@eip_information)
        end

        it "should return the hash that represents the EIP info" do
          allow(@cli).to receive(:ask).with("Which EIP would you like to move?\n", Integer).and_return(1)
          result = ask_which_eip_to_move(@eip_information)
          expect(result).to eq({eip: @eip, ip_address: @eip.ip, instance_name: "example-hostname-01", layer_id: 12345})
        end
      end

      context "#ask_which_target_instance" do
        before do
          @moveable_eip = {eip: @eip, ip_address: @eip.ip, instance_name: "example-hostname-01", layer_id: 12345}
        end

        it "should ask us which instance we want to move the EIP to" do
          allow(@opsworks).to receive(:describe_instances).and_return(@instances)
          expect(@cli).to receive(:ask).with("What is your target instance?\n", Integer).and_return(1)
          ask_which_target_instance(@moveable_eip)
        end

        it "should return the single instance id of the target instance" do
          allow(@opsworks).to receive(:describe_instances).and_return(@instances)
          allow(@cli).to receive(:ask).with("What is your target instance?\n", Integer).and_return(1)
          result = ask_which_target_instance(@moveable_eip)
          expect(result).to eq('some-id')
        end
      end
    end
  end
end
