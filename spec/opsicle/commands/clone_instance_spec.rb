require "spec_helper"
require "opsicle"
require 'gli'
require "opsicle/user_profile"
require "opsicle/aws_instance_manager_helper"

module Opsicle
  describe CloneInstance do
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
                                       :ebs_optimized => 'ebs_optimized', :tenancy => 'tenancy', :instance_id => 'some-id')
      @instance2 = double('instance2', :hostname => 'example-hostname-02', :status => 'active',
                                       :ami_id => 'ami_id', :instance_type => 'instance_type',
                                       :agent_version => 'agent_version', :stack_id => 1234567890,
                                       :layer_ids => [12345, 67890], :auto_scaling_type => 'auto_scaling_type',
                                       :os => 'os', :ssh_key_name => 'ssh_key_name',
                                       :availability_zone => 'availability_zone', :virtualization_type => 'virtualization_type',
                                       :subnet_id => 'subnet_id', :architecture => 'architecture',
                                       :root_device_type => 'root_device_type', :install_updates_on_boot => 'install_updates_on_boot',
                                       :ebs_optimized => 'ebs_optimized', :tenancy => 'tenancy', :instance_id => 'some-id')
      @instances = double('instances', :instances => [@instance1, @instance2])
      @layer = double('layer1', :name => 'layer-1', :layer_id => 12345, :instances => [@instance1, @instance2])
      @layer1 = double('layer1', :name => 'layer-1', :layer_id => 12345, :instances => [@instance1, @instance2])
      @layer2 = double('layer2', :name => 'layer-2', :layer_id => 67890, :instances => [@instance1, @instance2])
      @layers = double('layers', :layers => [@layer1, @layer2])
      @new_instance = double('new_instance', :instance_id => 1029384756)
      @stack = double('stack', :vpc_id => "vpc-123456", :id => 1234567890)
      @stacks = double('stacks', :stacks => [@stack])
      @opsworks = double('opsworks', :describe_instances => @instances, :describe_layers => @layers,
                                     :create_instance => @new_instance, :describe_stacks => @stacks,
                                     :start_instance => @new_instance)
      @ec2 = double('ec2')
      @config = double('config', :opsworks_config => {:stack_id => 1234567890})
      @client = double('client', :config => @config, :opsworks => @opsworks, :ec2 => @ec2)
      allow(Client).to receive(:new).with(:environment).and_return(@client)
      allow(@instances).to receive(:each_with_index)
      @agent_version_1 = double('agent_version', :version => '3434-20160316181345')
      @agent_version_2 = double('agent_version', :version => '3435-20160406115841')
      @agent_version_3 = double('agent_version', :version => '3436-20160418214624')
      @agent_versions = double('agent_versions', :agent_versions => [@agent_version_1, @agent_version_2, @agent_version_3])
      allow(@opsworks).to receive(:describe_agent_versions).and_return(@agent_versions)
      tag1 = double('tag', :value => 'Subnet', :key => 'Name')
      @tags = [tag1]
      @current_subnet = double('subnet', :tags => @tags, :availability_zone => 'us-east-1b')
      allow(Aws::EC2::Subnet).to receive(:new).and_return(@current_subnet)
      @cli = HighLine.new
      allow_any_instance_of(HighLine).to receive(:ask).with("Layer?\n", Integer).and_return(2)
      allow_any_instance_of(HighLine).to receive(:ask).with("Instances? (enter as a comma separated list)\n", String).and_return('2')
      allow_any_instance_of(HighLine).to receive(:ask).with("Do you wish to override this hostname?\n1) Yes\n2) No", Integer).and_return(2)
      allow_any_instance_of(HighLine).to receive(:ask).with("Please write in the new instance's hostname and press ENTER:").and_return('example-hostname')
      allow_any_instance_of(HighLine).to receive(:ask).with("Do you wish to override this AMI ID? By overriding, you are choosing to override the current AMI ID for all of the following instances you're cloning.\n1) Yes\n2) No", Integer).and_return(2)
      allow_any_instance_of(HighLine).to receive(:ask).with("Which AMI ID?\n", Integer).and_return(1)
      allow_any_instance_of(HighLine).to receive(:ask).with("Do you wish to override this agent version? By overriding, you are choosing to override the current agent version for all of the following instances you're cloning.\n1) Yes\n2) No", Integer).and_return(2)
      allow_any_instance_of(HighLine).to receive(:ask).with("Which agent version?\n", Integer).and_return(1)
      allow_any_instance_of(HighLine).to receive(:ask).with("Do you wish to override this instance type?\n1) Yes\n2) No", Integer).and_return(2)
      allow_any_instance_of(HighLine).to receive(:ask).with("Please write in the new instance type press ENTER:").and_return('t2.micro')
      allow_any_instance_of(HighLine).to receive(:ask).with("Do you wish to override this subnet ID? By overriding, you are choosing to override the current subnet ID for all of the following instances you're cloning.\n1) Yes\n2) No", Integer).and_return(2)
      allow_any_instance_of(HighLine).to receive(:ask).with("Which subnet ID?\n", Integer).and_return(1)
      allow_any_instance_of(HighLine).to receive(:ask).with("Do you wish to start this new instance?\n1) Yes\n2) No", Integer).and_return(1)
      allow_any_instance_of(HighLine).to receive(:ask).with("\nDo you wish to add EC2 tags to this instance?\n1) Yes\n2) No", Integer).and_return(2)
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

    context "#clone" do
      before do
        @manageable_instance = ManageableInstance.new(@layer, @stack, @opsworks, @ec2, @instance)
      end

      context "#make_new_hostname" do
        it "should make a unique incremented hostname" do
          instance1 = double('instance', :hostname => 'example-hostname-01')
          instance2 = double('instance', :hostname => 'example-hostname-02')
          allow(@layer).to receive(:instances).and_return([instance1, instance2])
          expect(make_new_hostname(@manageable_instance)).to eq('example-hostname-03')
        end

        it "should make a unique incremented hostname" do
          instance1 = double('instance', :hostname => 'example-hostname-01')
          instance2 = double('instance', :hostname => 'example-hostname-02')
          instance3 = double('instance', :hostname => 'example-hostname-03')
          instance4 = double('instance', :hostname => 'example-hostname-04')
          allow(@layer).to receive(:instances).and_return([instance1, instance2, instance3, instance4])
          expect(make_new_hostname(@manageable_instance)).to eq('example-hostname-05')
        end
      end

      context "#increment_hostname" do
        it "should increment the hostname" do
          allow(@opsworks).to receive(:describe_agent_version).with({})
          expect(increment_hostname(@manageable_instance, 'example-hostname-01')).to eq('example-hostname-03')
        end
      end

      context '#verify_ami_id' do
        it "should check the ami id and ask if the user wants a new ami" do
          allow(@layer).to receive(:ami_id).and_return(nil)
          expect(@cli).to receive(:ask).with("Do you wish to override this AMI ID? By overriding, you are choosing to override the current AMI ID for all of the following instances you're cloning.\n1) Yes\n2) No", Integer).and_return(2)
          verify_ami_id(@manageable_instance)
        end

        it "should see if the layer already has overwritten the ami id" do
          expect(@layer).to receive(:ami_id)
          verify_ami_id(@manageable_instance)
        end

        it "should check gather the proper ami id" do
          allow(@layer).to receive(:ami_id).and_return(nil)
          allow(@cli).to receive(:ask).with("Do you wish to override this AMI ID? By overriding, you are choosing to override the current AMI ID for all of the following instances you're cloning.\n1) Yes\n2) No", Integer).and_return(2)
          @manageable_instance.ami_id = "8873"
          result = verify_ami_id(@manageable_instance)
          expect(result).to eq("8873")
        end
      end

      context '#verify_agent_version' do
        it "should check the agent version and ask if the user wants a new agent version" do
          allow(@layer).to receive(:agent_version).and_return(nil)
          expect(@cli).to receive(:ask).with("Do you wish to override this agent version? By overriding, you are choosing to override the current agent version for all of the following instances you're cloning.\n1) Yes\n2) No", Integer).and_return(2)
          verify_agent_version(@manageable_instance)
        end

        it "should see if the layer already has overwritten the agent version" do
          expect(@layer).to receive(:agent_version)
          verify_agent_version(@manageable_instance)
        end

        it "should check gather the proper agent version" do
          allow(@layer).to receive(:agent_version).and_return(nil)
          allow(@cli).to receive(:ask).with("Do you wish to override this agent version? By overriding, you are choosing to override the current agent version for all of the following instances you're cloning.\n1) Yes\n2) No", Integer).and_return(2)
          @manageable_instance.agent_version = "8873"
          result = verify_agent_version(@manageable_instance)
          expect(result).to eq("8873")
        end
      end

      context '#verify_subnet_id' do
        it "should check the subnet id and ask if the user wants a new subnet id" do
          allow(@layer).to receive(:subnet_id).and_return(nil)
          expect(@cli).to receive(:ask).with("Do you wish to override this subnet ID? By overriding, you are choosing to override the current subnet ID for all of the following instances you're cloning.\n1) Yes\n2) No", Integer).and_return(2)
          verify_subnet_id(@manageable_instance)
        end

        it "should see if the layer already has overwritten the subnet id" do
          expect(@layer).to receive(:subnet_id)
          verify_subnet_id(@manageable_instance)
        end

        it "should check gather the proper subnet id" do
          allow(@layer).to receive(:subnet_id).and_return(nil)
          allow(@cli).to receive(:ask).with("Do you wish to override this subnet ID? By overriding, you are choosing to override the current subnet ID for all of the following instances you're cloning.\n1) Yes\n2) No", Integer).and_return(2)
          @manageable_instance.subnet_id = "us-east-1a"
          result = verify_subnet_id(@manageable_instance)
          expect(result).to eq("us-east-1a")
        end
      end

      context '#verify_instance_type' do
        it "should check the agent version and ask if the user wants a new instance type" do
          allow(@layer).to receive(:ami_id).and_return(nil)
          expect(@cli).to receive(:ask).with("Do you wish to override this instance type?\n1) Yes\n2) No", Integer).and_return(2)
          verify_instance_type(@manageable_instance)
        end

        it "should check gather the proper instance type" do
          allow(@layer).to receive(:ami_id).and_return(nil)
          allow(@cli).to receive(:ask).with("Do you wish to override this instance type?\n1) Yes\n2) No", Integer).and_return(2)
          @manageable_instance.instance_type = "t2.small"
          result = verify_instance_type(@manageable_instance)
          expect(result).to eq("t2.small")
        end
      end

      context "#create_new_clone" do
        it "should create an instance" do
          allow(@layer).to receive(:add_new_instance)
          expect(@opsworks).to receive(:create_instance)
          create_new_clone(@manageable_instance, 'hostname', 'type', 'ami', 'agent_version', 'subnet_id')
        end

        it "should take information from old instance" do
          allow(@layer).to receive(:add_new_instance)
          expect(@manageable_instance).to receive(:stack_id)
          expect(@manageable_instance).to receive(:layer_ids)
          expect(@manageable_instance).to receive(:auto_scaling_type)
          expect(@manageable_instance).to receive(:os)
          expect(@manageable_instance).to receive(:ssh_key_name)
          expect(@manageable_instance).to receive(:virtualization_type)
          create_new_clone(@manageable_instance, 'hostname', 'type', 'ami', 'agent_version', 'subnet_id')
        end

        it "should return another new manageable instance" do
          allow(@layer).to receive(:add_new_instance)
          new_manageable_instance = create_new_clone(@manageable_instance, 'hostname', 'type', 'ami', 'agent_version', 'subnet_id')
          expect(new_manageable_instance).to be_an_instance_of(ManageableInstance)
        end
      end

      context "#start_new_instance" do
        it "should ask us if we want to start the new instance" do
          expect(@cli).to receive(:ask).with("Do you wish to start this new instance?\n1) Yes\n2) No", Integer)
          start_new_instance(@manageable_instance)
        end

        it "should allow @opsworks to start the new instance" do
          expect(@opsworks).to receive(:start_instance)
          start_new_instance(@manageable_instance)
        end

        context "#add_tags" do
          it "should properly ask us if we want to add tags to the newly running instance" do
            expect(@cli).to receive(:ask).with("\nDo you wish to add EC2 tags to this instance?\n1) Yes\n2) No", Integer)
            add_tags(@manageable_instance)
          end

          it "should properly add tags to the manageable_instance" do
            allow(@cli).to receive(:ask).with("\nDo you wish to add EC2 tags to this instance?\n1) Yes\n2) No", Integer).and_return(1)
            allow(@cli).to receive(:ask).with("How many tags do you wish to add? Please write in the number as an integer and press ENTER:")
            allow(@cli).to receive(:ask).with("Please write in the new tag name and press ENTER:")
            allow(@cli).to receive(:ask).with("Please write in the new tag value and press ENTER:")
            expect(@manageable_instance).to receive(:add_tags)
            add_tags(@manageable_instance)
          end
        end
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
                                   :opsworks => @opsworks,
                                   :ec2 => @ec2)
        expect(Client).to receive(:new).with(:environment).and_return(@client)
        CloneInstance.new(:environment)
      end
    end
  end
end
