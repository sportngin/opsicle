require 'gli'
require "opsicle/user_profile"
require "opsicle/manageable_layer"
require "opsicle/manageable_instance"
require "opsicle/manageable_stack"
require "opsicle/creatable_instance"
require "opsicle/aws_instance_manager_helper"
# require "opsicle/aws_manageable_instance"

module Opsicle
  class MoveEip
    include Opsicle::AwsInstanceManagerHelper

    def initialize(environment)
      @client = Client.new(environment)
      @opsworks = @client.opsworks
      @ec2 = @client.ec2
      stack_id = @client.config.opsworks_config[:stack_id]
      @stack = ManageableStack.new(@client.config.opsworks_config[:stack_id], @opsworks)
      @cli = HighLine.new
      @new_instance_id = nil

      puts "Stack ID = #{@stack.id}"
    end

    def execute(options={})
      move_eip
    end

    def move_eip
      @stack.get_eips
      eip_information = gather_eip_information
      moveable_eip = ask_which_eip_to_move(eip_information)
      target_instance_id = ask_which_target_instance(moveable_eip)
      @stack.transfer_eip(moveable_eip, target_instance_id)
      puts "\nEIP #{moveable_eip[:ip_address]} was moved to instance #{target_instance_id}"
    end
  end
end
