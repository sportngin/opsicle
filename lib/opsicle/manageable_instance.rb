module Opsicle
  class ManageableInstance
    attr_accessor :hostname, :status, :layer, :stack, :ami_id, :instance_type, :instance_id, :new_instance_id,
                  :agent_version, :stack_id, :layer_ids, :auto_scaling_type, :os, :ssh_key_name, :availability_zone,
                  :virtualization_type, :subnet_id, :architecture, :root_device_type, :install_updates_on_boot,
                  :ebs_optimized, :tenancy, :opsworks, :ec2

    def initialize(layer, stack, opsworks, ec2, instance=nil)
      unless instance.nil?
        self.hostname = instance.hostname
        self.status = instance.status
        self.ami_id = instance.ami_id
        self.instance_type = instance.instance_type
        self.agent_version = instance.agent_version
        self.stack_id = instance.stack_id
        self.layer_ids = instance.layer_ids
        self.auto_scaling_type = instance.auto_scaling_type
        self.os = instance.os
        self.ssh_key_name = instance.ssh_key_name
        self.availability_zone = instance.availability_zone
        self.virtualization_type = instance.virtualization_type
        self.subnet_id = instance.subnet_id
        self.architecture = instance.architecture
        self.root_device_type = instance.root_device_type
        self.install_updates_on_boot = instance.install_updates_on_boot
        self.ebs_optimized = instance.ebs_optimized
        self.tenancy = instance.tenancy
        self.instance_id = instance.instance_id
      end

      self.layer = layer
      self.stack = stack
      self.opsworks = opsworks
      self.ec2 = ec2
    end

    def status
      @opsworks.describe_instances(instance_ids: [instance_id]).instances.first.status
    end

    def add_tags(tags)
      ec2_instance_id = @opsworks.describe_instances(instance_ids: [instance_id]).instances.first.ec2_instance_id
      @ec2.create_tags(resources: [ ec2_instance_id ], tags: tags)
    end
  end
end
