require 'gli'
require "opsicle/user_profile"
require "opsicle/opsworks_adapter"
require "opsicle/manageable_layer"
require "opsicle/manageable_instance"
require "opsicle/manageable_stack"
require "opsicle/question_asker/eip_asker"

module Opsicle
  class MoveEip

    def initialize(environment)
      @client = Client.new(environment)
      @opsworks_adapter = OpsworksAdapter.new(@client)
      stack_id = @client.config.opsworks_config[:stack_id]
      @cli = HighLine.new
      @stack = ManageableStack.new(stack_id, @opsworks_adapter, @cli)

      @eip_asker = QuestionAsker::EipAsker.new({
        opsworks_adapter: @opsworks_adapter,
        highline_client: @cli
      })
    end

    def execute(options={})
      puts "Stack ID = #{@stack.id}"
      move_eip
      puts "\nEIP #{moveable_eip[:ip_address]} was moved to instance #{target_instance_id}"
    end

    def move_eip
      eip_information = @stack.gather_eips
      moveable_eip = eip_asker.which_eip_should_move(eip_information)
      target_instance_id = eip_asker.which_instance_should_get_eip(moveable_eip)
      @stack.transfer_eip(moveable_eip, target_instance_id)
    end
  end
end
