require 'gli'
require "opsicle/user_profile"
require "opsicle/opsworks_adapter"
require "opsicle/manageable_layer"
require "opsicle/manageable_instance"
require "opsicle/manageable_stack"
require "opsicle/questionnaire/eip_inquiry"

module Opsicle
  class MoveEip

    def initialize(environment)
      @client = Client.new(environment)
      @opsworks_adapter = OpsworksAdapter.new(@client)
      stack_id = @client.config.opsworks_config[:stack_id]
      @cli = HighLine.new
      @stack = ManageableStack.new(stack_id, @opsworks_adapter, @cli)

      @eip_inquiry = Questionnaire::EipInquiry.new(
        opsworks_adapter: @opsworks_adapter,
        highline_client: @cli
      )
    end

    def execute(options={})
      puts "Stack ID = #{@stack.id}"
      moved_values = move_eip
      puts "\nEIP #{moved_values[:ip_address]} was moved to instance #{moved_values[:target_instance_id]}"
    end

    def move_eip
      eip_information = @stack.eips
      moveable_eip = @eip_inquiry.which_eip_should_move(eip_information)
      target_instance_id = @eip_inquiry.which_instance_should_get_eip(moveable_eip)
      @stack.transfer_eip(moveable_eip, target_instance_id)
      { ip_address: moveable_eip[:ip_address], target_instance_id: target_instance_id }
    end
    private :move_eip
  end
end
