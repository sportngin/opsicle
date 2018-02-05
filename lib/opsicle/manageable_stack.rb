module Opsicle
  class ManageableStack
    attr_accessor :id, :opsworks, :stack, :vpc_id, :eips, :cli

    def initialize(stack_id, opsworks, cli=nil)
      self.id = stack_id
      self.opsworks = opsworks
      self.cli = cli
      self.stack = get_stack
      self.vpc_id = self.stack.vpc_id
      self.eips = nil
    end

    def get_stack
      @opsworks.describe_stacks({ :stack_ids => [self.id.to_s] }).stacks.first
    end

    def get_eips
      self.eips = @opsworks.describe_elastic_ips(stack_id: self.id.to_s).elastic_ips
    end

    def transfer_eip(moveable_eip, target_instance_id)
      @opsworks.associate_elastic_ip({ elastic_ip: moveable_eip[:ip_address], instance_id: target_instance_id })
    end

    def instances
      @opsworks.describe_instances(stack_id: self.id).instances
    end

    def deleteable_instances(layer)
      instances.select{ |instance| instance.auto_scaling_type.nil?  && instance.status == "stopped" && instance.layer_ids.include?(layer.layer_id) }
    end

    def stoppable_states
      %w(start_failed stop_failed online running_setup setup_failed booting rebooting)
    end

    def stoppable_instances(layer)
      instances.select{ |instance| instance.elastic_ip.nil?  && stoppable_states.include?(instance.status) && instance.layer_ids.include?(layer.layer_id) }
    end
  end
end
