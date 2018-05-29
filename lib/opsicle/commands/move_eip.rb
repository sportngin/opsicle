require 'gli'
require "opsicle/user_profile"
require "opsicle/opsworks_adapter"
require "opsicle/manageable_layer"
require "opsicle/manageable_instance"
require "opsicle/manageable_stack"
require "opsicle/aws_instance_manager_helper"

module Opsicle
  class MoveEip
    include Opsicle::AwsInstanceManagerHelper

    def initialize(environment)
      @client = Client.new(environment)
      @opsworks_adapter = OpsworksAdapter.new(@client)
      stack_id = @client.config.opsworks_config[:stack_id]
      @cli = HighLine.new
      @stack = ManageableStack.new(stack_id, @opsworks_adapter, @cli)
    end

    def execute(options={})
      puts "Stack ID = #{@stack.id}"
      move_eip
      puts "\nEIP #{moveable_eip[:ip_address]} was moved to instance #{target_instance_id}"
    end

    def move_eip
      eip_information = gather_eip_information(@stack.get_eips)
      moveable_eip = ask_which_eip_to_move(eip_information)
      target_instance_id = ask_which_target_instance(moveable_eip)
      @stack.transfer_eip(moveable_eip, target_instance_id)
    end
  end
end
