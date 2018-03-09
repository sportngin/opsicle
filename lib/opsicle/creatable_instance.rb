module Opsicle
  class CreatableInstance
    attr_accessor :layer, :stack, :new_instance_id, :opsworks, :ec2, :cli

    def initialize(layer, stack, opsworks, ec2, cli)
      self.layer = layer
      self.stack = stack
      self.opsworks = opsworks
      self.ec2 = ec2
      self.cli = cli
      self.new_instance_id = nil
    end

    def create(options)
      puts "\nCreating an instance..."

      new_instance_hostname = make_new_hostname
      puts ""
      ami_id = select_ami_id
      puts ""
      agent_version = select_agent_version
      puts ""
      subnet_id = select_subnet_id
      puts ""
      instance_type = ask_for_new_option('instance type')
      puts ""

      create_new_instance(new_instance_hostname, instance_type, ami_id, agent_version, subnet_id)
      start_new_instance
    end

    def make_new_hostname
      new_instance_hostname = auto_generated_hostname || nil
      puts "\nAutomatically generated hostname: #{new_instance_hostname}\n" if new_instance_hostname
      new_instance_hostname = ask_for_new_option("instance's hostname") if ask_for_overriding_permission("hostname", false)
      new_instance_hostname
    end

    def hostname
      self.layer.instances.first.hostname if self.layer.instances.first
    end

    def auto_generated_hostname
      if hostname =~ /\d\d\z/
        increment_hostname
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

    def select_ami_id
      instances = @opsworks.describe_instances(stack_id: @stack.id).instances
      ami_ids = instances.collect { |i| i.ami_id }.uniq
      ami_ids << "Provide a different AMI ID."
      ami_id = ask_for_possible_options(ami_ids, "AMI ID")

      if ami_id == "Provide a different AMI ID."
        ami_id = ask_for_new_option('AMI ID')
      end

      self.layer.ami_id = ami_id

      ami_id
    end

    def select_agent_version
      agents = @opsworks.describe_agent_versions(stack_id: @stack.id).agent_versions
      version_ids = agents.collect { |i| i.version }.uniq
      agent_version = ask_for_possible_options(version_ids, "agent version")
      self.layer.agent_version = agent_version
      agent_version
    end

    def select_subnet_id
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

      self.layer.subnet_id = subnet_id
      subnet_id
    end

    def os
      self.layer.instances.first.os if self.layer.instances.first
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
        stack_id: self.stack.id, # required
        layer_ids: [self.layer.layer_id], # required
        instance_type: instance_type, # required
        hostname: new_instance_hostname,
        ami_id: ami_id,
        subnet_id: subnet_id,
        agent_version: agent_version,
        os: os || 'Custom'
      })
      self.new_instance_id = new_instance.instance_id
      self.layer.add_new_instance(new_instance_id)
      puts "New instance #{new_instance_hostname} has been created: #{new_instance_id}"
    end

    def start_new_instance
      if ask_to_start_instance
        @opsworks.start_instance(instance_id: self.new_instance_id)
        puts "\nNew instance is starting…"
        add_tags
      end
    end

    def add_tags
      if ask_to_add_tags
        tags = []

        tag_count.times do
          tags << define_tag
        end

        ec2_instance_id = @opsworks.describe_instances(instance_ids: [new_instance_id]).instances.first.ec2_instance_id
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
      ans = @cli.ask("Do you wish to add EC2 tags to this instance?\n1) Yes\n2) No", Integer)
      ans == 1
    end

    def ask_to_start_instance
      ans = @cli.ask("Do you wish to start this new instance?\n1) Yes\n2) No", Integer)
      ans == 1
    end
  end
end
