require 'gli'
require "opsicle/user_profile"
require "opsicle/opsworks_adapter"
require "opsicle/ec2_adapter"
require "opsicle/manageable_layer"
require "opsicle/manageable_stack"
require "opsicle/creatable_instance"

module Opsicle
  class CreateInstance

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
      layer.get_cloneable_instances
      create_instance(layer, options)
      layer.ami_id = nil
      layer.agent_version = nil
    end

    def create_instance(layer, options)
      CreatableInstance.new(layer, @stack, @opsworks_adapter.client, @ec2_adapter.client, @cli).create(options)
    end

    def select_layer
      puts "\nLayers:\n"
      ops_layers = @opsworks_adapter.get_layers(@stack.id)

      layers = []
      ops_layers.each do |layer|
        layers << ManageableLayer.new(layer.name, layer.layer_id, @stack, @opsworks_adapter.client, @ec2_adapter.client, @cli)
      end

      layers.each_with_index { |layer, index| puts "#{index.to_i + 1}) #{layer.name}" }
      layer_index = @cli.ask("Layer?\n", Integer) { |q| q.in = 1..layers.length.to_i } - 1
      layers[layer_index]
    end
  end
end
