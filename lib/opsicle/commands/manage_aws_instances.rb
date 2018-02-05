require 'gli'
require "opsicle/user_profile"
require "opsicle/manageable_layer"
require "opsicle/manageable_instance"
require "opsicle/manageable_stack"
require "opsicle/creatable_instance"
require "opsicle/aws_instance_manager_helper"

module Opsicle
  class ManageAwsInstances
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

    def clone_instance(options={})
      layer = select_layer
      all_instances = layer.get_cloneable_instances
      instance_to_clone = select_instances(all_instances)

      if options[:'with-defaults']
        instances.each { |instance| instance.clone_with_defaults(options) }
      else
        instances.each { |instance| instance.clone(options) }
      end

      layer.ami_id = nil
      layer.agent_version = nil
    end

    def create_instance(options={})
      layer = select_layer
      layer.get_cloneable_instances
      CreatableInstance.new(layer, @stack, @opsworks, @ec2, @cli).create(options)
      layer.ami_id = nil
      layer.agent_version = nil
    end

    def stop_instance(options={})
      layer = select_layer
      instances = select_deletable_or_stoppable_instances(layer, :stop)
      stop_or_delete(instances)
    end

    def delete_instance(options={})
      layer = select_layer
      instances = select_deletable_or_stoppable_instances(layer, :delete)
      stop_or_delete(instances)
    end

    def move_eip(options={})
      @stack.move_eip
    end

    def add_tags(options={})
      layer = select_layer
      all_instances = layer.get_cloneable_instances
      instances_to_add_tags = select_instances(all_instances)
      instances_to_add_tags.each { |instance| instance.add_tags({ add_tags_mode: true }) }
    end
  end
end
