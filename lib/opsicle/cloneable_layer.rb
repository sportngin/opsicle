module Opsicle
  class CloneableLayer
    attr_accessor :name, :layer_id, :instances, :opsworks, :cli, :agent_version, :ami_id

    def initialize(name, layer_id, opsworks, cli)
      self.name = name
      self.layer_id = layer_id
      self.opsworks = opsworks
      self.cli = cli
      self.instances = []
    end

    def get_cloneable_instances
      ops_instances = @opsworks.describe_instances({ :layer_id => layer_id }).instances
      ops_instances.each do |instance|
        self.instances << CloneableInstance.new(instance, self, @opsworks, @cli)
      end
      self.instances
    end

    def add_new_instance(instance_id)
      instance = @opsworks.describe_instances({ :instance_ids => [instance_id] }).instances.first
      self.instances << CloneableInstance.new(instance, self, @opsworks, @cli)
    end
  end
end
