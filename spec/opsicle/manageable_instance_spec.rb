require "spec_helper"
require "opsicle"
require 'gli'
require "opsicle/user_profile"

module Opsicle
  describe ManageableInstance do
    before do
      @instance = double('instance1', :hostname => 'example-hostname-01', :status => 'online',
                                       :ami_id => 'ami_id', :instance_type => 'instance_type',
                                       :agent_version => 'agent_version', :stack_id => 1234567890,
                                       :layer_ids => [12345, 67890], :auto_scaling_type => 'auto_scaling_type',
                                       :os => 'os', :ssh_key_name => 'ssh_key_name',
                                       :availability_zone => 'availability_zone', :virtualization_type => 'virtualization_type',
                                       :subnet_id => 'subnet_id', :architecture => 'architecture',
                                       :root_device_type => 'root_device_type', :install_updates_on_boot => 'install_updates_on_boot',
                                       :ebs_optimized => 'ebs_optimized', :tenancy => 'tenancy', :instance_id => 'some-id', :ec2_instance_id => 12345)
      @layer = double('layer1', :name => 'layer-1', :layer_id => 12345, :instances => [@instance], :ami_id => nil, :agent_version => nil)
      @instances = double('instances array', :instances => [@instance])
      @opsworks = double('opsworks', :describe_instances => @instances)
      @ec2 = double('ec2', :create_tags => true)
      @stack = double('stack')
      tag1 = { key: "tag_example1", value: "tag_value1" }
      tag2 = { key: "tag_example2", value: "tag_value2" }
      @tags = [tag1, tag2]
      @manageable_instance = ManageableInstance.new(@layer, @stack, @opsworks, @ec2, @instance)
      # allow(@layer).to receive(:ami_id=)
      # allow(@layer).to receive(:ami_id)
      # allow(@layer).to receive(:agent_version=)
      # allow(@layer).to receive(:agent_version)
      # allow(@layer).to receive(:add_new_instance)
      # allow(@layer).to receive(:subnet_id=)
      # allow(@layer).to receive(:subnet_id)
      # @agent_version_1 = double('agent_version', :version => '3434-20160316181345')
      # @agent_version_2 = double('agent_version', :version => '3435-20160406115841')
      # @agent_version_3 = double('agent_version', :version => '3436-20160418214624')
      # @agent_versions = double('agent_versions', :agent_versions => [@agent_version_1, @agent_version_2, @agent_version_3])
      # allow(@opsworks).to receive(:describe_agent_versions).with({:stack_id=>1234567890}).and_return(@agent_versions)
      # tag1 = double('tag', :value => 'Subnet', :key => 'Name')
      # @tags = [tag1]
      # @subnet1 = double('subnet', :vpc_id => 'vpc-123456', :subnet_id => 'subnet-123456', :tags => @tags, :availability_zone => 'us-east-1b')
      # @subnet2 = double('subnet', :vpc_id => 'vpc-123456', :subnet_id => 'subnet-789123', :tags => @tags, :availability_zone => 'us-east-1b')
      # @subnet3 = double('subnet', :vpc_id => 'vpc-123456', :subnet_id => 'subnet-456789', :tags => @tags, :availability_zone => 'us-east-1b')
      # @subnets = double('subnets', :subnets => [@subnet1, @subnet2, @subnet3])
      # allow(@stack).to receive(:vpc_id).and_return('vpc-123456')
      # @instances = double('instances', :instances => [@instance])
      # allow(@ec2).to receive(:describe_subnets).and_return(@subnets)
      # allow(@opsworks).to receive(:describe_instances).with({:stack_id=>1234567890}).and_return(@instances)
      # @current_subnet = double('subnet', :tags => @tags, :availability_zone => 'us-east-1b')
      # allow(Aws::EC2::Subnet).to receive(:new).and_return(@current_subnet)
      # @cli = double('cli', :ask => 2)
    end

    context "#add_tags" do
      it "should call create_tags for the ec2 client" do
        allow(@opsworks).to receive(:describe_instances).and_return(@instances)
        expect(@ec2).to receive(:create_tags)
        @manageable_instance.add_tags(@tags)
      end

      it "should properly add tags to the instance" do
        result = @manageable_instance.add_tags(@tags)
        expect(result).to eq(true)
      end
    end

    context "#status" do
      it "should gather the status of the instance" do
        allow(@opsworks).to receive(:describe_instances).and_return(@instances)
        status = @manageable_instance.status
        expect(status).to eq("online")
      end

      it "should let @opsworks to gather teh status of the first instance" do
        expect(@opsworks).to receive(:describe_instances)
        @manageable_instance.status
      end
    end
  end
end
