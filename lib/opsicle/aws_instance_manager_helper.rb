module Opsicle
  module AwsInstanceManagerHelper
    def select_layer
      puts "\nLayers:\n"
      ops_layers = @opsworks.describe_layers({ :stack_id => @stack.id }).layers

      layers = []
      ops_layers.each do |layer|
        layers << ManageableLayer.new(layer.name, layer.layer_id, @stack, @opsworks, @ec2, @cli)
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

    def select_deletable_or_stoppable_instances(layer, stop_or_delete)
      if stop_or_delete == :stop
        instances = @stack.stoppable_instances(layer)
        specific_words = { adjective: "stoppable", verb: "stop" }
      elsif stop_or_delete == :delete
        instances = @stack.deleteable_instances(layer)
        specific_words = { adjective: "deletable", verb: "delete" } 
      end
      
      return_array = []
      if instances.empty?
        puts "There are no #{specific_words[:adjective]} instances."
      else
        puts "\n#{specific_words[:adjective].capitalize} Instances:\n"
        instances.each_with_index { |instance, index| puts "#{index.to_i + 1}) #{instance.status} - #{instance.hostname}" }
        instance_indices_string = @cli.ask("Which instances would you like to #{specific_words[:verb]}? (enter as a comma separated list)\n", String)
        instance_indices_list = instance_indices_string.split(/,\s*/)
        instance_indices_list.map! { |instance_index| instance_index.to_i - 1 }
        instance_indices_list.each do |index|
          return_array << instances[index]
        end
      end
      return_array
    end

    def stop_or_delete(instances, stop_or_delete)
      if stop_or_delete == :stop
        specific_words = { past_tense: "stopped", verb: "stop" }
      elsif stop_or_delete == :delete
        specific_words = { past_tense: "deleted", verb: "delete" } 
      end

      instances.each do |instance|
        begin
          if stop_or_delete == :stop
            @opsworks.stop_instance(instance_id: instance.instance_id)
          elsif stop_or_delete == :delete
            @opsworks.delete_instance(instance_id: instance.instance_id)
          end
          
          puts "Successfully #{specific_words[:past_tense]} #{instance.hostname}"
        rescue
          puts "Failed to #{specific_words[:verb]} #{instance.hostname}"
        end
      end
    end
  end
end
