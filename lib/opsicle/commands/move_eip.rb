require 'gli'
require "opsicle/user_profile"
require "opsicle/cloneable_layer"
require "opsicle/cloneable_instance"
require "opsicle/cloneable_stack"

module Opsicle
  class MoveEip

    def initialize(environment)
      @client = Client.new(environment)
      @opsworks = @client.opsworks
      @ec2 = @client.ec2
      stack_id = @client.config.opsworks_config[:stack_id]
      @cli = HighLine.new
      @stack = CloneableStack.new(@client.config.opsworks_config[:stack_id], @opsworks, @cli)
    end

    def execute(options={})
      puts "Stack ID = #{@stack.id}"
      @stack.move_eip
    end
  end
end
