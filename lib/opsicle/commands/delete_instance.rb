require 'gli'
require "opsicle/user_profile"
require "opsicle/opsworks_adapter"
require "opsicle/ec2_adapter"
require "opsicle/manageable_layer"
require "opsicle/manageable_instance"
require "opsicle/manageable_stack"

module Opsicle
  class DeleteInstance

    def initialize(environment)
      @client = Client.new(environment)
      @ec2_adapter = Ec2Adapter.new(@client)
      @opsworks_adapter = OpsworksAdapter.new(@client)
      stack_id = @client.config.opsworks_config[:stack_id]
      @stack = ManageableStack.new(stack_id, @opsworks_adapter.client)
      @cli = HighLine.new
    end

    def execute(options={})
      puts "Stack ID = #{@stack.id}"
      layer = select_layer
      instances_to_delete = select_instances(layer)
      instances_to_delete.each do |instance|
        begin
          @opsworks_adapter.delete_instance(instance.instance_id)
          puts "Successfully deleted #{instance.hostname}"
        rescue
          puts "Failed to delete #{instance.hostname}"
        end
      end
    end

    def deleteable_instances(layer)
      @stack.deleteable_instances(layer)
    end

    def select_layer
      puts "\nLayers:\n"
      ops_layers = @opsworks_adapter.get_layers(@stack_id)

      layers = []
      ops_layers.each do |layer|
        layers << ManageableLayer.new(layer.name, layer.layer_id, @stack, @opsworks_adapter.client, @ec2_adapter.client, @cli)
      end

      layers.each_with_index { |layer, index| puts "#{index.to_i + 1}) #{layer.name}" }
      layer_index = @cli.ask("Layer?\n", Integer) { |q| q.in = 1..layers.length.to_i } - 1
      layers[layer_index]
    end

    def select_instances(layer)
      instances = deleteable_instances(layer)
      return_array = []
      if instances.empty?
        puts "There are no deletable instances."
      else
        puts "\nDeleteable Instances:\n"
        instances.each_with_index { |instance, index| puts "#{index.to_i + 1}) #{instance.status} - #{instance.hostname}" }
        instance_indices_string = @cli.ask("Which instances would you like to delete? (enter as a comma separated list)\n", String)
        instance_indices_list = instance_indices_string.split(/,\s*/)
        instance_indices_list.map! { |instance_index| instance_index.to_i - 1 }
        instance_indices_list.each do |index|
          return_array << instances[index]
        end
      end
      return_array
    end
  end
end
