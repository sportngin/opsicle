require 'gli'
require "opsicle/user_profile"
require "opsicle/manageable_layer"
require "opsicle/manageable_instance"
require "opsicle/manageable_stack"
require "opsicle/aws_instance_manager_helper"

module Opsicle
  class CreateInstance
    include Opsicle::AwsInstanceManagerHelper

    def initialize(environment)
      @client = Client.new(environment)
      @opsworks = @client.opsworks
      @ec2 = @client.ec2
      stack_id = @client.config.opsworks_config[:stack_id]
      @stack = ManageableStack.new(@client.config.opsworks_config[:stack_id], @opsworks)
      @cli = HighLine.new
      @new_instance_id = nil

      puts "Stack ID = #{@stack.id}"
    end

    def execute(options={})
      @layer = select_layer
      @layer.get_cloneable_instances
      new_manageable_instance = ManageableInstance.new(@layer, @stack, @opsworks, @ec2)
      create(new_manageable_instance)
      @layer.ami_id = nil
      @layer.agent_version = nil
    end

    def create(instance)
      puts "\nCreating an instance..."
      options = { create_fresh: true }

      new_instance_hostname = make_new_hostname(instance, options)
      puts ""
      ami_id = verify_ami_id(instance, options)
      puts ""
      agent_version = verify_agent_version(instance, options)
      puts ""
      subnet_id = verify_subnet_id(instance, options)
      puts ""
      instance_type = ask_for_new_option('instance type')
      puts ""

      new_manageable_instance = create_new_instance(instance, new_instance_hostname, instance_type, ami_id, agent_version, subnet_id)
      start_new_instance(new_manageable_instance)
    end
  end
end
