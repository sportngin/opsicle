module Opsicle
  class ManageableStack
    attr_accessor :id, :opsworks_adapter, :stack, :vpc_id, :eips, :cli

    def initialize(stack_id, opsworks_adapter, cli=nil)
      self.id = stack_id
      self.opsworks_adapter = opsworks_adapter
      self.cli = cli
      self.stack = @opsworks_adapter.stack(self.id)
      self.vpc_id = self.stack.vpc_id
    end

    def get_eips
      @opsworks_adapter.elastic_ips(self.id.to_s)
    end

    def transfer_eip(moveable_eip, target_instance_id)
      @opsworks_adapter.associate_elastic_ip(moveable_eip[:ip_address], target_instance_id)
    end

    def instances
      @opsworks_adapter.instances_by_stack(stack_id: self.id).instances
    end

    def deleteable_instances(layer)
      instances.select do |instance|
        instance.auto_scaling_type.nil? &&
        instance.status == "stopped" &&
        instance.layer_ids.include?(layer.layer_id)
      end
    end

    def stoppable_instances(layer)
      instances.select do |instance|
        instance.elastic_ip.nil? &&
        stoppable_states.include?(instance.status) &&
        instance.layer_ids.include?(layer.layer_id)
      end
    end

    def stoppable_states
      %w(start_failed stop_failed online running_setup setup_failed booting rebooting)
    end
  end
end
