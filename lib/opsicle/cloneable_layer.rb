module Opsicle
  class CloneableLayer
    attr_accessor :name, :layer_id, :stack, :instances, :opsworks, :ec2, :cli, :agent_version, :ami_id, :subnet_id

    def initialize(name, layer_id, stack, opsworks, ec2, cli)
      self.name = name
      self.layer_id = layer_id
      self.stack = stack
      self.opsworks = opsworks
      self.ec2 = ec2
      self.cli = cli
      self.instances = []
    end

    def get_cloneable_instances
      ops_instances = @opsworks.describe_instances({ :layer_id => layer_id }).instances
      ops_instances.each do |instance|
        self.instances << CloneableInstance.new(instance, self, stack, @opsworks, @ec2, @cli)
      end
      self.instances
    end

    def add_new_instance(instance_id)
      instance = @opsworks.describe_instances({ :instance_ids => [instance_id] }).instances.first
      self.instances << CloneableInstance.new(instance, self, stack, @opsworks, @ec2, @cli)
    end
  end
end
