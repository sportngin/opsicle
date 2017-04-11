module Opsicle
  class CloneableInstance
    attr_accessor :hostname, :status, :layer, :ami_id, :instance_type, :agent_version, :stack_id, :layer_ids,
                  :auto_scaling_type, :os, :ssh_key_name, :availability_zone, :virtualization_type, :subnet_id,
                  :architecture, :root_device_type, :install_updates_on_boot, :ebs_optimized, :tenancy, :opsworks, :cli

    def initialize(instance, layer, opsworks, cli)
      self.hostname = instance.hostname
      self.status = instance.status
      self.layer = layer
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
      self.opsworks = opsworks
      self.cli = cli
    end

    def clone(options)
      puts "\nCloning an instance..."
      
      new_instance_hostname = make_new_hostname(self.hostname)
      ami_id = verify_ami_id
      agent_version = verify_agent_version
      instance_type = verify_instance_type

      create_new_instance(new_instance_hostname, instance_type, ami_id, agent_version)
    end

    def make_new_hostname(old_hostname)
      all_sibling_hostnames = self.layer.instances.collect { |instance| instance.hostname }

      if old_hostname =~ /\d\d\z/
        new_instance_hostname = increment_hostname(old_hostname, all_sibling_hostnames)
      else
        new_instance_hostname = old_hostname << "-clone"
      end
        
      puts "\nAutomatically generated hostname: #{new_instance_hostname}\n"
      rewriting = @cli.ask("Do you wish to rewrite this hostname?\n1) Yes\n2) No", Integer)
      new_instance_hostname = @cli.ask("Please write in the new instance's hostname and press ENTER:") if rewriting == 1

      new_instance_hostname
    end

    def increment_hostname(hostname, all_sibling_hostnames)
      until hostname_unique?(hostname, all_sibling_hostnames) do
        hostname = hostname.gsub(/(\d\d\z)/) { "#{($1.to_i + 1).to_s.rjust(2, '0')}" }
      end
      hostname
    end

    def hostname_unique?(hostname, all_sibling_hostnames)
      !all_sibling_hostnames.include?(hostname)
    end

    def verify_ami_id
      if self.layer.ami_id
        ami_id = self.layer.ami_id
      else
        puts "\nCurrent AMI id is #{self.ami_id}"
        rewriting = @cli.ask("Do you wish to override this AMI? By overriding, you are choosing to override the current AMI for all instances you are cloning.\n1) Yes\n2) No", Integer)
        ami_id = rewriting == 1 ? @cli.ask("Please write in the new AMI id press ENTER:") : self.ami_id
      end

      self.layer.ami_id = ami_id
      ami_id
    end

    def verify_agent_version
      if self.layer.agent_version
        agent_version = self.layer.agent_version
      else
        puts "\nCurrent agent version is #{self.agent_version}"
        rewriting = @cli.ask("Do you wish to override this version? By overriding, you are choosing to override the current agent version for all instances you are cloning.\n1) Yes\n2) No", Integer)
        agent_version = rewriting == 1 ? get_new_agent_version : self.agent_version
      end

      self.layer.agent_version = agent_version
      agent_version
    end

    def get_new_agent_version
      agents = @opsworks.describe_agent_versions(stack_id: self.stack_id).agent_versions

      version_ids = []
      agents.each do |agent|
        version_ids << agent.version
      end

      version_ids.each_with_index { |id, index| puts "#{index.to_i + 1}) #{id}"}
      id_index = @cli.ask("Which agent version ID?\n", Integer) { |q| q.in = 1..version_ids.length.to_i } - 1
      version_ids[id_index]
    end

    def verify_instance_type
      puts "\nCurrent instance type is #{self.instance_type}"
      rewriting = @cli.ask("Do you wish to override this instance type?\n1) Yes\n2) No", Integer)
      instance_type = rewriting == 1 ? @cli.ask("Please write in the new instance type press ENTER:") : self.instance_type
      instance_type
    end

    def create_new_instance(new_instance_hostname, instance_type, ami_id, agent_version)
      new_instance = @opsworks.create_instance({
        stack_id: self.stack_id, # required
        layer_ids: self.layer_ids, # required
        instance_type: instance_type, # required
        auto_scaling_type: self.auto_scaling_type, # accepts load, timer
        hostname: new_instance_hostname,
        os: self.os,
        ami_id: ami_id,
        ssh_key_name: self.ssh_key_name,
        availability_zone: self.availability_zone,
        virtualization_type: self.virtualization_type,
        subnet_id: self.subnet_id,
        architecture: self.architecture, # accepts x86_64, i386
        root_device_type: self.root_device_type, # accepts ebs, instance-store
        install_updates_on_boot: self.install_updates_on_boot,
        #ebs_optimized: self.ebs_optimized,
        agent_version: agent_version,
        tenancy: self.tenancy,
      })
      puts "\nNew instance has been created: #{new_instance.instance_id}"
    end
  end
end
