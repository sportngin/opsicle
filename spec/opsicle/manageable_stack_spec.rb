require "spec_helper"
require "opsicle"
require 'gli'
require "opsicle/user_profile"

module Opsicle
  describe ManageableStack do
    before do
      @stack = double('stack', :vpc_id => 'vpc-123456')
      @stacks = double('stacks', :stacks => [@stack])
      @opsworks = double('opsworks', :describe_stacks => @stacks)
      @eip = double('eip', :ip => '12.34.56.78')
      @eips = double('eip list', :elastic_ips => [@eip])
      @instance0 = double('instance0', :hostname => 'test_hostname', :layer_ids => [12345], :instance_id => 67890, :auto_scaling_type => nil, :status => "online", :elastic_ip => nil)
      @instance1 = double('instance1', :hostname => 'test_hostname', :layer_ids => [12345], :instance_id => 67890, :auto_scaling_type => nil, :status => "stopped", :elastic_ip => nil)
      @instance2 = double('instance2', :hostname => 'test_hostname', :layer_ids => [12345], :instance_id => 67890, :auto_scaling_type => nil, :status => "running_setup", :elastic_ip => true)
      @instance3 = double('instance3', :hostname => 'test_hostname', :layer_ids => [12345], :instance_id => 67890, :auto_scaling_type => nil, :status => "stopped", :elastic_ip => nil)
      @instances = double('instance list', :instances => [@instance0, @instance1, @instance2, @instance3])
      @layer = double('layer', :layer_id => 12345)
      @manageable_stack = ManageableStack.new(12345, @opsworks)
    end

    context "#get_stack" do
      it "should gather opsworks instances for that layer" do
        expect(@opsworks).to receive(:describe_stacks).and_return(@stacks)
        expect(@stacks).to receive(:stacks)
        @manageable_stack.get_stack
      end
    end

    context "#get_eips" do
      it "should let @opsworks to get the EIPs" do
        expect(@opsworks).to receive(:describe_elastic_ips).and_return(@eips)
        @manageable_stack.get_eips
      end

      it "should get a list of the EIPs" do
        allow(@opsworks).to receive(:describe_elastic_ips).and_return(@eips)
        result = @manageable_stack.get_eips
        expect(result).to eq([@eip])
      end
    end

    context "#transfer_eip" do
      it "should let @opsworks associate the EIP with a new instance" do
        moveable_eip = { eip: @eip, ip_address: @eip.ip, instance_name: @instance0.hostname, layer_id: @instance0.layer_ids.first }
        target_instance_id = @instance0.instance_id
        expect(@opsworks).to receive(:associate_elastic_ip)
        @manageable_stack.transfer_eip(moveable_eip, target_instance_id)
      end

      it "should properly transfer the EIP" do
        moveable_eip = { eip: @eip, ip_address: @eip.ip, instance_name: @instance0.hostname, layer_id: @instance0.layer_ids.first }
        target_instance_id = @instance0.instance_id
        allow(@opsworks).to receive(:associate_elastic_ip).and_return(true)
        result = @manageable_stack.transfer_eip(moveable_eip, target_instance_id)
        expect(result).to eq(true)
      end
    end

    context "#instances" do
      it "should allow @opsworks to look up the instances associated with this stack" do
        expect(@opsworks).to receive(:describe_instances).and_return(@instances)
        @manageable_stack.instances
      end

      it "should allow list out all of the instances with this stack" do
        allow(@opsworks).to receive(:describe_instances).and_return(@instances)
        result = @manageable_stack.instances
        expect(result).to eq([@instance0, @instance1, @instance2, @instance3])
      end
    end

    context "#deletable_instances" do
      it "should only collect instances that are deletable" do
        allow(@opsworks).to receive(:describe_instances).and_return(@instances)
        result = @manageable_stack.deletable_instances(@layer)
        expect(result).to eq([@instance1, @instance3])
      end
    end

    context "#stoppable_instances" do
      it "should only collect instances that are stoppable" do
        allow(@opsworks).to receive(:describe_instances).and_return(@instances)
        result = @manageable_stack.stoppable_instances(@layer)
        expect(result).to eq([@instance0])
      end

      it "should not include an instance that has the EIP" do
        allow(@opsworks).to receive(:describe_instances).and_return(@instances)
        result = @manageable_stack.stoppable_instances(@layer)
        expect(result.include? (@instance2)).to eq(false)
      end
    end
  end
end
