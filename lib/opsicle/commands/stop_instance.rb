require 'gli'
require "opsicle/user_profile"
require "opsicle/opsworks_adapter"
require "opsicle/ec2_adapter"
require "opsicle/manageable_layer"
require "opsicle/manageable_instance"
require "opsicle/manageable_stack"

module Opsicle
  class StopInstance

    def initialize(environment)
      @client = Client.new(environment)
      @ec2_adapter = Ec2Adapter.new(@client)
      @opsworks_adapter = OpsworksAdapter.new(@client)
      stack_id = @client.config.opsworks_config[:stack_id]
      @stack = ManageableStack.new(stack_id, @opsworks_adapter)
      @cli = HighLine.new
    end

    def execute(options={})
      puts "Stack ID = #{@stack.id}"
      layer = select_layer
      instances_to_stop = select_instances(layer)
      instances_to_stop.each do |instance|
        begin
          @opsworks_adapter.stop_instance(instance.instance_id)
          puts "Stopping instance #{instance.hostname}..."
        rescue
          puts "Failed to stop #{instance.hostname}"
        end
      end
    end

    def stoppable_instances(layer)
      @stack.stoppable_instances(layer)
    end

    def select_layer
      puts "\nLayers:\n"
      ops_layers = @opsworks_adapter.layers(@stack.id)

      layers = []
      ops_layers.each do |layer|
        layers << ManageableLayer.new(layer.name, layer.layer_id, @stack, @opsworks_adapter.client, @ec2_adapter.client, @cli)
      end

      layers.each_with_index { |layer, index| puts "#{index.to_i + 1}) #{layer.name}" }
      layer_index = @cli.ask("Layer?\n", Integer) { |q| q.in = 1..layers.length.to_i } - 1
      layers[layer_index]
    end

    def select_instances(layer)
      instances = stoppable_instances(layer)
      return_array = []
      if instances.empty?
        puts "There are no stoppable instances."
      else
        puts "\nStoppable Instances:\n"
        instances.each_with_index { |instance, index| puts "#{index.to_i + 1}) #{instance.status} - #{instance.hostname}" }
        instance_indices_string = @cli.ask("Which instances would you like to stop? (enter as a comma separated list)\n", String)
        instance_indices_list = instance_indices_string.split(/,\s*/)
        check_for_valid_indices!(instance_indices_list, instances.count)
        instance_indices_list.map! { |instance_index| instance_index.to_i - 1 }
        instance_indices_list.each do |index|
          return_array << instances[index]
        end
      end
      return_array
    end

    def check_for_valid_indices!(instance_indices_list, option_count)
      valid_indices = 1..option_count

      unless instance_indices_list.all?{ |i| valid_indices.include?(i.to_i) }
        raise StandardError, "At least one of the indices passed is invalid. Please try again."
      end
    end
    private :check_for_valid_indices!
  end
end
