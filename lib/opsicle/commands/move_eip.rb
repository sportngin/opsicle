require 'gli'
require "opsicle/user_profile"
require "opsicle/manageable_layer"
require "opsicle/manageable_instance"
require "opsicle/manageable_stack"

module Opsicle
  class MoveEip

    def initialize(environment)
      @client = Client.new(environment)
      @opsworks_adpater = OpsworksAdapter.new(@client)
      stack_id = @client.config.opsworks_config[:stack_id]
      @cli = HighLine.new
      @stack = ManageableStack.new(stack_id, @opsworks_adpater.client, @cli)
    end

    def execute(options={})
      puts "Stack ID = #{@stack.id}"
      @stack.move_eip
    end
  end
end
