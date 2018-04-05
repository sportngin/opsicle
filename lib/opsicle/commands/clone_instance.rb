require 'gli'
require "opsicle/user_profile"
require "opsicle/opsworks_adapter"
require "opsicle/ec2_adapter"
require "opsicle/manageable_layer"
require "opsicle/manageable_instance"
require "opsicle/manageable_stack"

module Opsicle
  class CloneInstance

    def initialize(environment)
      @client = Client.new(environment)
      @opsworks_adapater = OpsworksAdapter.new(@client)
      @ec2_adapter = Ec2Adapter.new(@client)
      stack_id = @client.config.opsworks_config[:stack_id]
      @stack = ManageableStack.new(stack_id, @opsworks_adapater.client)
      @cli = HighLine.new
    end

    def execute(options={})
      puts "Stack ID = #{@stack.id}"
      layer = select_layer
      all_instances = layer.get_cloneable_instances
      instance_to_clone = select_instances(all_instances)
      clone_instances(instance_to_clone, options)
      layer.ami_id = nil
      layer.agent_version = nil
    end

    def clone_instances(instances, options)
      if options[:'with-defaults']
        instances.each { |instance| instance.clone_with_defaults(options) }
      else
        instances.each { |instance| instance.clone(options) }
      end
    end

    def select_layer
      puts "\nLayers:\n"
      ops_layers = @opsworks_adapater.get_layers(@stack.id)

      layers = []
      ops_layers.each do |layer|
        layers << ManageableLayer.new(layer.name, layer.layer_id, @stack, @opsworks_adapater.client, @ec2_adapter.client, @cli)
      end

      layers.each_with_index { |layer, index| puts "#{index.to_i + 1}) #{layer.name}" }
      layer_index = @cli.ask("Layer?\n", Integer) { |q| q.in = 1..layers.length.to_i } - 1
      layers[layer_index]
    end

    def select_instances(instances)
      puts "\nInstances:\n"
      instances.each_with_index { |instance, index| puts "#{index.to_i + 1}) #{instance.status} - #{instance.hostname}" }
      instance_indices_string = @cli.ask("Instances? (enter as a comma separated list)\n", String)
      instance_indices_list = instance_indices_string.split(/,\s*/)
      instance_indices_list.map! { |instance_index| instance_index.to_i - 1 }

      return_array = []
      instance_indices_list.each do |index|
        return_array << instances[index]
      end
      return_array
    end
  end
end
