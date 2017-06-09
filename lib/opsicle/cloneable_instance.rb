module Opsicle
  class CloneableInstance
    attr_accessor(
      :hostname,
      :status,
      :layer,
      :ami_id,
      :instance_type,
      :instance_id,
      :new_instance_id,
      :agent_version,
      :stack_id,
      :layer_ids,
      :auto_scaling_type,
      :os,
      :ssh_key_name,
      :availability_zone,
      :virtualization_type,
      :subnet_id,
      :architecture,
      :root_device_type,
      :install_updates_on_boot,
      :ebs_optimized,
      :tenancy,
      :opsworks,
      :cli
    )

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
      self.instance_id = instance.instance_id
      self.new_instance_id = nil
    end

    def clone(options)
      puts "\nCloning an instance..."

      new_instance_hostname = make_new_hostname
      ami_id = verify_ami_id
      agent_version = verify_agent_version
      subnet_id = verify_subnet_id
      instance_type = verify_instance_type

      create_new_instance(new_instance_hostname, instance_type, ami_id, agent_version, subnet_id)
      start_new_instance
    end


    def clone_with_defaults(options)
      puts "\nCloning an instance..."
      new_hostname = auto_generated_hostname
      create_new_instance(new_hostname, instance_type, ami_id, agent_version, subnet_id)
      opsworks.start_instance(instance_id: new_instance_id)
      puts "\nNew instance is starting…"
    end

    def make_new_hostname
      new_instance_hostname = auto_generated_hostname
      puts "\nAutomatically generated hostname: #{new_instance_hostname}\n"
      new_instance_hostname = ask_for_new_option("instance's hostname") if ask_for_overriding_permission("hostname", false)
      new_instance_hostname
    end

    def auto_generated_hostname
      if hostname =~ /\d\d\z/
        increment_hostname
      else
        hostname << "-clone"
      end
    end

    def sibling_hostnames
      self.layer.instances.collect { |instance| instance.hostname }
    end

    def increment_hostname
      name = hostname
      until hostname_unique?(name) do
        name = name.gsub(/(\d\d\z)/) { "#{($1.to_i + 1).to_s.rjust(2, '0')}" }
      end
      name
    end

    def sibling_hostnames
      self.layer.instances.map(&:hostname)
    end

    def hostname_unique?(name)
      !sibling_hostnames.include?(name)
    end

    def verify_ami_id
      if self.layer.ami_id
        ami_id = self.layer.ami_id
      else
        puts "\nCurrent AMI id is #{self.ami_id}"

        if ask_for_overriding_permission("AMI ID", true)
          instances = @opsworks.describe_instances(stack_id: self.stack_id).instances
          ami_ids = instances.collect { |i| i.ami_id }.uniq
          ami_ids << "Provide a different AMI ID."
          ami_id = ask_for_possible_options(ami_ids, "AMI ID")

          if ami_id == "Provide a different AMI ID."
            ami_id = ask_for_new_option('AMI ID')
          end
        else
          ami_id = self.ami_id
        end
      end

      self.layer.ami_id = ami_id
      ami_id
    end

    def verify_agent_version
      if self.layer.agent_version
        agent_version = self.layer.agent_version
      else
        puts "\nCurrent agent version is #{self.agent_version}"

        if ask_for_overriding_permission("agent version", true)
          agents = @opsworks.describe_agent_versions(stack_id: self.stack_id).agent_versions
          version_ids = agents.collect { |i| i.version }.uniq
          agent_version = ask_for_possible_options(version_ids, "agent version")
        else
          agent_version = self.agent_version
        end
      end

      self.layer.agent_version = agent_version
      agent_version
    end

    def verify_subnet_id
      if self.layer.subnet_id
        subnet_id = self.layer.subnet_id
      else
        puts "\nCurrent subnet id is #{self.subnet_id}"

        if ask_for_overriding_permission("subnet ID", true)
          instances = @opsworks.describe_instances(stack_id: self.stack_id).instances
          subnet_ids = instances.collect { |i| i.subnet_id }.uniq
          subnet_ids << "Provide a different subnet ID."
          subnet_id = ask_for_possible_options(subnet_ids, "subnet ID")

          if subnet_id == "Provide a different subnet ID."
            subnet_id = ask_for_new_option('subnet ID')
          end
        else
          subnet_id = self.subnet_id
        end
      end

      self.layer.subnet_id = subnet_id
      subnet_id
    end

    def verify_instance_type
      puts "\nCurrent instance type is #{self.instance_type}"
      rewriting = ask_for_overriding_permission("instance type", false)
      instance_type = rewriting ? ask_for_new_option('instance type') : self.instance_type
      instance_type
    end

    def ask_for_possible_options(arr, description)
      arr.each_with_index { |id, index| puts "#{index.to_i + 1}) #{id}"}
      id_index = @cli.ask("Which #{description}?\n", Integer) { |q| q.in = 1..arr.length.to_i } - 1
      arr[id_index]
    end

    def ask_for_new_option(description)
      @cli.ask("Please write in the new #{description} and press ENTER:")
    end

    def ask_for_overriding_permission(description, overriding_all)
      if overriding_all
        ans = @cli.ask("Do you wish to override this #{description}? By overriding, you are choosing to override the current #{description} for all instances you are cloning.\n1) Yes\n2) No", Integer)
      else
        ans = @cli.ask("Do you wish to override this #{description}?\n1) Yes\n2) No", Integer)
      end
      ans == 1
    end

    def create_new_instance(new_instance_hostname, instance_type, ami_id, agent_version, subnet_id)
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
        subnet_id: subnet_id,
        architecture: self.architecture, # accepts x86_64, i386
        root_device_type: self.root_device_type, # accepts ebs, instance-store
        install_updates_on_boot: self.install_updates_on_boot,
        #ebs_optimized: self.ebs_optimized,
        agent_version: agent_version,
        tenancy: self.tenancy,
      })
      self.new_instance_id = new_instance.instance_id
      self.layer.add_new_instance(new_instance_id)
      puts "\nNew instance #{new_instance_hostname} has been created: #{new_instance_id}"
    end

    def start_new_instance
      if ask_to_start_instance
        @opsworks.start_instance(instance_id: self.new_instance_id)
        puts "\nNew instance is starting…"
      end
    end

    def ask_to_start_instance
      ans = @cli.ask("Do you wish to start this new instance?\n1) Yes\n2) No", Integer)
      ans == 1
    end
  end
end
