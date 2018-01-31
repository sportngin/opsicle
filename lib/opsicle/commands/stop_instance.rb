require 'gli'
require "opsicle/user_profile"
require "opsicle/manageable_layer"
require "opsicle/manageable_instance"
require "opsicle/manageable_stack"

module Opsicle
  class StopInstance

    def initialize(environment)
      @client = Client.new(environment)
      @opsworks = @client.opsworks
      @ec2 = @client.ec2
      stack_id = @client.config.opsworks_config[:stack_id]
      @stack = ManageableStack.new(@client.config.opsworks_config[:stack_id], @opsworks)
      @cli = HighLine.new
    end

    def execute(options={})
      puts "Stack ID = #{@stack.id}"
      instances_to_stop = select_instances
      instances_to_stop.each do |instance|
        begin
          @opsworks.stop_instance(instance_id: instance.instance_id)
          puts "Stopping instance #{instance.hostname}..."
        rescue
          puts "Failed to stop #{instance.hostname}"
        end
      end
    end

    def stoppable_instances
      @stack.stoppable_instances
    end

    def select_instances
      instances = stoppable_instances
      return_array = []
      if instances.empty?
        puts "There are no stoppable instances"
      else
        puts "\nStoppable Instances:\n"
        instances.each_with_index { |instance, index| puts "#{index.to_i + 1}) #{instance.status} - #{instance.hostname}" }
        instance_indices_string = @cli.ask("Which instances would you like to stop? (enter as a comma separated list)\n", String)
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
