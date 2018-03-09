require 'gli'
require "opsicle/user_profile"
require "opsicle/manageable_layer"
require "opsicle/manageable_instance"
require "opsicle/manageable_stack"

module Opsicle
  class MoveEip

    def initialize(environment)
      @client = Client.new(environment)
      @opsworks = @client.opsworks
      @ec2 = @client.ec2
      stack_id = @client.config.opsworks_config[:stack_id]
      @cli = HighLine.new
      @stack = ManageableStack.new(@client.config.opsworks_config[:stack_id], @opsworks, @cli)
    end

    def execute(options={})
      puts "Stack ID = #{@stack.id}"
      @stack.move_eip
    end
  end
end
