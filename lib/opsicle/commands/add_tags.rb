require 'gli'
require "opsicle/user_profile"
require "opsicle/manageable_layer"
require "opsicle/manageable_instance"
require "opsicle/manageable_stack"
require "opsicle/aws_instance_manager_helper"

module Opsicle
  class AddTags
    include Opsicle::AwsInstanceManagerHelper

    def initialize(environment)
      @client = Client.new(environment)
      @opsworks = @client.opsworks
      @ec2 = @client.ec2
      stack_id = @client.config.opsworks_config[:stack_id]
      @stack = ManageableStack.new(@client.config.opsworks_config[:stack_id], @opsworks)
      @cli = HighLine.new

      puts "Stack ID = #{@stack.id}"
    end

    def execute(options={})
      @layer = select_layer
      all_instances = @layer.get_cloneable_instances
      instances_to_add_tags = select_instances(all_instances)
      instances_to_add_tags.each { |instance| add_tags(instance, { add_tags_mode: true }) }
    end
  end
end
