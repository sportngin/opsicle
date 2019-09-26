module Opsicle
  class ManageableInstance
    attr_accessor(
      :hostname,
      :status,
      :layer,
      :stack,
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
      :ebs_optimized,
      :tenancy,
      :opsworks,
      :ec2,
      :cli
    )

    def initialize(instance, layer, stack, opsworks, ec2, cli)
      self.hostname = instance.hostname
      self.status = instance.status
      self.layer = layer
      self.stack = stack
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
      self.ebs_optimized = instance.ebs_optimized
      self.tenancy = instance.tenancy
      self.opsworks = opsworks
      self.ec2 = ec2
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

    def find_subnet_name(subnet)
      tags = subnet.tags
      tag = nil
      tags.each { |t| tag = t if t.key == 'Name' }
      tag.value if tag
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

          self.layer.ami_id = ami_id   # only set AMI ID for whole layer if they override it
        else
          ami_id = self.ami_id
        end
      end

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

          self.layer.agent_version = agent_version   # only set agent version for whole layer if they override
        else
          agent_version = self.agent_version
        end
      end

      agent_version
    end

    def verify_subnet_id
      if self.layer.subnet_id
        subnet_id = self.layer.subnet_id
      else
        current_subnet = Aws::EC2::Subnet.new(id: self.subnet_id, client: @ec2)
        subnet_name = find_subnet_name(current_subnet)
        puts "\nCurrent subnet ID is \"#{subnet_name}\" #{current_subnet.availability_zone} (#{self.subnet_id})"

        if ask_for_overriding_permission("subnet ID", true)
          ec2_subnets = ec2.describe_subnets.subnets
          subnets = []

          ec2_subnets.each do |subnet|
            if subnet.vpc_id == stack.vpc_id
              subnet_name = find_subnet_name(subnet)
              zone_name = subnet.availability_zone
              subnet_id = subnet.subnet_id
              subnets << "\"#{subnet_name}\" #{zone_name} (#{subnet_id})"
            end
          end

          subnets = subnets.sort
          subnet_id = ask_for_possible_options(subnets, "subnet ID")
          subnet_id = subnet_id.scan(/(subnet-[a-z0-9]*)/).first.first if subnet_id

          self.layer.subnet_id = subnet_id   # only set the subnet ID for whole layer if they override it
        else
          subnet_id = self.subnet_id
        end
      end

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
        ans = @cli.ask("Do you wish to override this #{description}? By overriding, you are choosing to override the current #{description} for all of the following instances you're cloning.\n1) Yes\n2) No", Integer)
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
        # availability_zone: self.availability_zone,
        subnet_id: subnet_id,
        virtualization_type: self.virtualization_type,
        architecture: self.architecture, # accepts x86_64, i386
        root_device_type: self.root_device_type, # accepts ebs, instance-store
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
        add_tags
      end
    end

    def add_tags(options={})
      raise ArgumentError, 'The instance must be running to add tags' if options[:add_tags_mode] && @status != "online"

      if ask_to_add_tags
        tags = []

        tag_count.times do
          tags << define_tag
        end

        ec2_instance_id = @opsworks.describe_instances(instance_ids: [new_instance_id || instance_id]).instances.first.ec2_instance_id
        @ec2.create_tags(resources: [ ec2_instance_id ], tags: tags)
      end
    end

    def define_tag
      tag_key = ask_for_new_option('tag name')
      tag_value = ask_for_new_option('tag value')
      { key: tag_key, value: tag_value }
    end

    def tag_count
      @cli.ask("How many tags do you wish to add? Please write in the number as an integer and press ENTER:").to_i
    end

    def ask_to_add_tags
      ans = @cli.ask("\nDo you wish to add EC2 tags to this instance?\n1) Yes\n2) No", Integer)
      ans == 1
    end

    def ask_to_start_instance
      ans = @cli.ask("Do you wish to start this new instance?\n1) Yes\n2) No", Integer)
      ans == 1
    end
  end
end
