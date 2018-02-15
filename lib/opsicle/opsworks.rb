require 'pathname'

module Opsicle
  class Opsworks
    attr_reader :client

    def initialize(client)
      @client = client.opsworks # Aws::OpsWorks::Client.new(options)
    end

    # def describe_stacks(stack_id)
    #   @client.describe_stacks({ :stack_ids => [stack_id] }).stacks
    # end

    def describe_layers(stack_id)
      @client.describe_layers(stack_id: stack_id).layers
    end

    def start_instance(instance_id)
      @client.start_instance(instance_id: instance_id)
    end

    # def instance_type

    # end
  end
end
