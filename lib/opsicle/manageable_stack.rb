module Opsicle
  class ManageableStack
    attr_accessor :id, :opsworks_adapter, :stack, :vpc_id, :eips, :cli

    STOPPABLE_STATES = %w(start_failed stop_failed online running_setup setup_failed booting rebooting)

    def initialize(stack_id, opsworks_adapter, cli=nil)
      self.id = stack_id
      self.opsworks_adapter = opsworks_adapter
      self.cli = cli
      self.stack = @opsworks_adapter.stack(id)
      self.vpc_id = self.stack.vpc_id
    end

    def gather_eips
      eips = @opsworks_adapter.elastic_ips(id)
      eip_information = []

      eips.each do |eip|
        next unless eip.instance_id
        instance_id = eip.instance_id
        instance = @opsworks_adapter.instance(instance_id)
        instance_name = instance.hostname
        layer_id = instance.layer_ids.first
        layer = @opsworks_adapter.layer(layer_id)
        layer_name = layer.name
        eip_information << { eip: eip, ip_address: eip.ip, instance_name: instance_name, layer_id: layer_id }
      end

      eip_information
    end

    def transfer_eip(moveable_eip, target_instance_id)
      @opsworks_adapter.associate_elastic_ip(moveable_eip[:ip_address], target_instance_id)
    end

    def instances
      @opsworks_adapter.instances_by_stack(id)
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
        STOPPABLE_STATES.include?(instance.status) &&
        instance.layer_ids.include?(layer.layer_id)
      end
    end
  end
end
