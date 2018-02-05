require 'gli'
require "opsicle/user_profile"
require "opsicle/manageable_layer"
require "opsicle/manageable_instance"
require "opsicle/manageable_stack"
require "opsicle/creatable_instance"

module Opsicle
  class CloneInstance

    def initialize(environment)
      @client = Client.new(environment)
      @opsworks = @client.opsworks
      @ec2 = @client.ec2
      stack_id = @client.config.opsworks_config[:stack_id]
      @stack = ManageableStack.new(@client.config.opsworks_config[:stack_id], @opsworks)
      @cli = HighLine.new
    end

    def execute_clone_instance(options={})
      puts "Stack ID = #{@stack.id}"
      layer = select_layer
      all_instances = layer.get_cloneable_instances
      instance_to_clone = select_instances(all_instances)
      clone_instances(instance_to_clone, options)
      layer.ami_id = nil
      layer.agent_version = nil
    end

    def execute_create_instance(options={})
      puts "Stack ID = #{@stack.id}"
      layer = select_layer
      layer.get_cloneable_instances
      create_instance(layer, options)
      layer.ami_id = nil
      layer.agent_version = nil
    end

    def execute_stop_instance(options={})
      puts "Stack ID = #{@stack.id}"
      layer = select_layer
      instances_to_stop = select_instances(layer)
      instances_to_stop.each do |instance|
        begin
          @opsworks.stop_instance(instance_id: instance.instance_id)
          puts "Stopping instance #{instance.hostname}..."
        rescue
          puts "Failed to stop #{instance.hostname}"
        end
      end
    end

    def execute_delete_instance(options={})
      puts "Stack ID = #{@stack.id}"
      layer = select_layer
      instances_to_delete = select_instances(layer)
      instances_to_delete.each do |instance|
        begin
          @opsworks.delete_instance(instance_id: instance.instance_id)
          puts "Successfully deleted #{instance.hostname}"
        rescue
          puts "Failed to delete #{instance.hostname}"
        end
      end
    end

    def execute_move_eip(options={})
      puts "Stack ID = #{@stack.id}"
      @stack.move_eip
    end

    def clone_instances(instances, options)
      if options[:'with-defaults']
        instances.each { |instance| instance.clone_with_defaults(options) }
      else
        instances.each { |instance| instance.clone(options) }
      end
    end

    def create_instance(layer, options)
      CreatableInstance.new(layer, @stack, @opsworks, @ec2, @cli).create(options)
    end

    # def select_layer
    #   puts "\nLayers:\n"
    #   ops_layers = @opsworks.describe_layers({ :stack_id => @stack.id }).layers

    #   layers = []
    #   ops_layers.each do |layer|
    #     layers << ManageableLayer.new(layer.name, layer.layer_id, @stack, @opsworks, @ec2, @cli)
    #   end

    #   layers.each_with_index { |layer, index| puts "#{index.to_i + 1}) #{layer.name}" }
    #   layer_index = @cli.ask("Layer?\n", Integer) { |q| q.in = 1..layers.length.to_i } - 1
    #   layers[layer_index]
    # end

    # def select_instances(instances)
    #   puts "\nInstances:\n"
    #   instances.each_with_index { |instance, index| puts "#{index.to_i + 1}) #{instance.status} - #{instance.hostname}" }
    #   instance_indices_string = @cli.ask("Instances? (enter as a comma separated list)\n", String)
    #   instance_indices_list = instance_indices_string.split(/,\s*/)
    #   instance_indices_list.map! { |instance_index| instance_index.to_i - 1 }

    #   return_array = []
    #   instance_indices_list.each do |index|
    #     return_array << instances[index]
    #   end
    #   return_array
    # end
  end
end
