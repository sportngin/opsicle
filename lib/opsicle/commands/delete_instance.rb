require 'gli'
require "opsicle/user_profile"
require "opsicle/cloneable_layer"
require "opsicle/cloneable_instance"
require "opsicle/cloneable_stack"

module Opsicle
  class DeleteInstance

    def initialize(environment)
      @client = Client.new(environment)
      @opsworks = @client.opsworks
      @ec2 = @client.ec2
      stack_id = @client.config.opsworks_config[:stack_id]
      @stack = CloneableStack.new(@client.config.opsworks_config[:stack_id], @opsworks)
      @cli = HighLine.new
    end

    def execute(options={})
      puts "Stack ID = #{@stack.id}"
      instances_to_delete = select_instances
      instances_to_delete.each do |instance|
        begin
          @opsworks.delete_instance(instance_id: instance.instance_id)
          puts "Successfully deleted #{instance.hostname}"
        rescue
          puts "Failed to delete #{instance.hostname}"
        end
      end
    end

    def deleteable_instances
      @stack.deleteable_instances

    end

    def select_instances
      instances = deleteable_instances
      return_array = []
      if instances.empty?
        puts "There are no deletable instances"
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
