require "spec_helper"
require "opsicle"
require 'gli'
require "opsicle/user_profile"

module Opsicle
  describe CloneInstance do
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
      @instances = double('instances', :instances => [@instance1, @instance2])
      @layer1 = double('layer1', :name => 'layer-1', :layer_id => 12345, :instances => [@instance1, @instance2])
      @layer2 = double('layer2', :name => 'layer-2', :layer_id => 67890, :instances => [@instance1, @instance2])
      @layers = double('layers', :layers => [@layer1, @layer2])
      @new_instance = double('new_instance', :instance_id => 1029384756)
      @stack = double('stack')
      @stacks = double('stacks', :stacks => [@stack])
      @opsworks = double('opsworks', :describe_instances => @instances, :describe_layers => @layers,
                                     :create_instance => @new_instance, :describe_stacks => @stacks,
                                     :start_instance => @new_instance)
      @config = double('config', :opsworks_config => {:stack_id => 1234567890})
      @client = double('client', :config => @config, :opsworks => @opsworks)
      allow(Client).to receive(:new).with(:environment).and_return(@client)
      allow(@instances).to receive(:each_with_index)
      @agent_version_1 = double('agent_version', :version => '3434-20160316181345')
      @agent_version_2 = double('agent_version', :version => '3435-20160406115841')
      @agent_version_3 = double('agent_version', :version => '3436-20160418214624')
      @agent_versions = double('agent_versions', :agent_versions => [@agent_version_1, @agent_version_2, @agent_version_3])
      allow(@opsworks).to receive(:describe_agent_versions).and_return(@agent_versions)
      allow_any_instance_of(HighLine).to receive(:ask).with("Layer?\n", Integer).and_return(2)
      allow_any_instance_of(HighLine).to receive(:ask).with("Instances? (enter as a comma separated list)\n", String).and_return('2')
      allow_any_instance_of(HighLine).to receive(:ask).with("Do you wish to override this hostname?\n1) Yes\n2) No", Integer).and_return(2)
      allow_any_instance_of(HighLine).to receive(:ask).with("Please write in the new instance's hostname and press ENTER:").and_return('example-hostname')
      allow_any_instance_of(HighLine).to receive(:ask).with("Do you wish to override this AMI ID? By overriding, you are choosing to override the current AMI ID for all instances you are cloning.\n1) Yes\n2) No", Integer).and_return(2)
      allow_any_instance_of(HighLine).to receive(:ask).with("Which AMI ID?\n", Integer).and_return(1)
      allow_any_instance_of(HighLine).to receive(:ask).with("Do you wish to override this agent version? By overriding, you are choosing to override the current agent version for all instances you are cloning.\n1) Yes\n2) No", Integer).and_return(2)
      allow_any_instance_of(HighLine).to receive(:ask).with("Which agent version?\n", Integer).and_return(1)
      allow_any_instance_of(HighLine).to receive(:ask).with("Do you wish to override this instance type?\n1) Yes\n2) No", Integer).and_return(2)
      allow_any_instance_of(HighLine).to receive(:ask).with("Please write in the new instance type press ENTER:").and_return('t2.micro')
      allow_any_instance_of(HighLine).to receive(:ask).with("Do you wish to override this subnet ID? By overriding, you are choosing to override the current subnet ID for all instances you are cloning.\n1) Yes\n2) No", Integer).and_return(2)
      allow_any_instance_of(HighLine).to receive(:ask).with("Which subnet ID?\n", Integer).and_return(1)
      allow_any_instance_of(HighLine).to receive(:ask).with("Do you wish to start this new instance?\n1) Yes\n2) No", Integer).and_return(1)
    end

    context "#execute" do
      it "lists all current layers" do
        expect(@opsworks).to receive(:describe_layers)
        CloneInstance.new(:environment).execute
      end

      it "lists all current instances" do
        expect(@opsworks).to receive(:describe_instances)
        CloneInstance.new(:environment).execute
      end
    end

    context "#select_layer" do
      it "should list layers" do
        expect(@opsworks).to receive(:describe_layers)
        CloneInstance.new(:environment).select_layer
      end

      it "should get the layer id" do
        expect(@layer2).to receive(:layer_id)
        CloneInstance.new(:environment).select_layer
      end
    end

    context "#select_instances" do
      it "should list instances" do
        expect(@instances).to receive(:[])
        CloneInstance.new(:environment).select_instances(@instances)
      end
    end

    context "#client" do
      it "generates a new AWS client from the given configs" do
        @config = double('config', :opsworks_config => {:stack_id => 1234567890})
        @client = double('client', :config => @config,
                                   :opsworks => @opsworks)
        expect(Client).to receive(:new).with(:environment).and_return(@client)
        CloneInstance.new(:environment)
      end
    end
  end
end
