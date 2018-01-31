module Opsicle
  class CloneableStack
    attr_accessor :id, :opsworks, :stack, :vpc_id

    def initialize(stack_id, opsworks)
      self.id = stack_id
      self.opsworks = opsworks
      self.stack = get_stack
      self.vpc_id = self.stack.vpc_id
    end

    def get_stack
      @opsworks.describe_stacks({ :stack_ids => [self.id.to_s] }).stacks.first
    end

    def instances
      @opsworks.describe_instances(stack_id: self.id).instances
    end

    def deleteable_instances
      instances.select{|instance| instance.auto_scaling_type.nil?  && instance.status == "stopped"}
    end

    def stoppable_states
      %w(start_failed stop_failed online running_setup setup_failed booting rebooting)
    end

    def stoppable_instances
      instances.select{|instance| instance.elastic_ip.nil?  && stoppable_states.include?(instance.status)}
    end
  end
end
