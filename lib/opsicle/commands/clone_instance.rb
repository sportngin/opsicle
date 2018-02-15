require 'gli'
require "opsicle/user_profile"
require "opsicle/manageable_layer"
require "opsicle/manageable_instance"
require "opsicle/manageable_stack"
require "opsicle/aws_instance_manager_helper"

module Opsicle
  class CloneInstance
    include Opsicle::AwsInstanceManagerHelper

    def initialize(environment)
      @client = Client.new(environment)
      @opsworks = @client.opsworks
      @ec2 = @client.ec2
      stack_id = @client.config.opsworks_config[:stack_id]
      @stack = ManageableStack.new(@client.config.opsworks_config[:stack_id], @opsworks)
      @cli = HighLine.new
      puts "Stack ID = #{@stack.id}"
    end

    def execute(options={})
      @layer = select_layer
      all_instances = @layer.get_cloneable_instances
      instances = select_instances(all_instances)
      
      if options[:'with-defaults']
        instances.each { |instance| clone_with_defaults(instance) }
      else
        instances.each { |instance| clone(instance) }
      end
      
      @layer.ami_id = nil
      @layer.agent_version = nil
    end

    def clone(instance)
      puts "\nCloning an instance..."
      new_instance_hostname = instance.make_new_hostname
      ami_id = instance.verify_ami_id
      agent_version = instance.verify_agent_version
      subnet_id = instance.verify_subnet_id
      instance_type = instance.verify_instance_type

      instance.create_new_instance(new_instance_hostname, instance_type, ami_id, agent_version, subnet_id)
      instance.start_new_instance
    end

    def clone_with_defaults(instance)
      puts "\nCloning an instance..."
      new_hostname = instance.auto_generated_hostname
      instance.create_new_instance(new_hostname, instance_type, ami_id, agent_version, subnet_id)
      @opsworks.start_instance(instance_id: new_instance_id)
      puts "\nNew instance is starting…"
      instance.add_tags
    end
  end
end
