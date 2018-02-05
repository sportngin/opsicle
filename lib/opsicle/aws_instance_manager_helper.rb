module Opsicle
  module AwsInstanceManagerHelper
    def select_layer
      puts "\nLayers:\n"
      ops_layers = @opsworks.describe_layers({ :stack_id => @stack.id }).layers

      layers = []
      ops_layers.each do |layer|
        layers << ManageableLayer.new(layer.name, layer.layer_id, @stack, @opsworks, @ec2, @cli)
      end

      layers.each_with_index { |layer, index| puts "#{index.to_i + 1}) #{layer.name}" }
      layer_index = @cli.ask("Layer?\n", Integer) { |q| q.in = 1..layers.length.to_i } - 1
      layers[layer_index]
    end

    def select_instances(instances)
      puts "\nInstances:\n"
      instances.each_with_index { |instance, index| puts "#{index.to_i + 1}) #{instance.status} - #{instance.hostname}" }
      instance_indices_string = @cli.ask("Instances? (enter as a comma separated list)\n", String)
      instance_indices_list = instance_indices_string.split(/,\s*/)
      instance_indices_list.map! { |instance_index| instance_index.to_i - 1 }

      return_array = []
      instance_indices_list.each do |index|
        return_array << instances[index]
      end
      return_array
    end

    def select_deletable_or_stoppable_instances(layer, stop_or_delete)
      if stop_or_delete == :stop
        instances = @stack.stoppable_instances(layer)
        specific_words = { adjective: "stoppable", verb: "stop" }
      elsif stop_or_delete == :delete
        instances = @stack.deleteable_instances(layer)
        specific_words = { adjective: "deletable", verb: "delete" } 
      end
      
      return_array = []
      if instances.empty?
        puts "There are no #{specific_words[:adjective]} instances."
      else
        puts "\n#{specific_words[:adjective].capitalize} Instances:\n"
        instances.each_with_index { |instance, index| puts "#{index.to_i + 1}) #{instance.status} - #{instance.hostname}" }
        instance_indices_string = @cli.ask("Which instances would you like to #{specific_words[:verb]}? (enter as a comma separated list)\n", String)
        instance_indices_list = instance_indices_string.split(/,\s*/)
        instance_indices_list.map! { |instance_index| instance_index.to_i - 1 }
        instance_indices_list.each do |index|
          return_array << instances[index]
        end
      end
      return_array
    end

    def stop_or_delete(instances, stop_or_delete)
      if stop_or_delete == :stop
        specific_words = { past_tense: "stopped", verb: "stop" }
      elsif stop_or_delete == :delete
        specific_words = { past_tense: "deleted", verb: "delete" } 
      end

      instances.each do |instance|
        begin
          if stop_or_delete == :stop
            @opsworks.stop_instance(instance_id: instance.instance_id)
          elsif stop_or_delete == :delete
            @opsworks.delete_instance(instance_id: instance.instance_id)
          end
          
          puts "Successfully #{specific_words[:past_tense]} #{instance.hostname}"
        rescue
          puts "Failed to #{specific_words[:verb]} #{instance.hostname}"
        end
      end
    end

    def make_new_hostname(instance, options={})
      new_instance_hostname = auto_generated_hostname(instance, options) || nil
      puts "\nAutomatically generated hostname: #{new_instance_hostname}\n" unless new_instance_hostname.empty?
      new_instance_hostname = ask_for_new_option("instance's hostname") if ask_for_overriding_permission("hostname", false)
      new_instance_hostname
    end

    def auto_generated_hostname(instance, options={})
      name = instance.hostname || @layer.instances.first.hostname if @layer.instances.first
      if name =~ /\d\d\z/
        increment_hostname(instance, name)
      else
        name << "-clone" unless options[:create_fresh]
      end
    end

    def increment_hostname(instance, name)
      until hostname_unique?(name) do
        name = name.gsub(/(\d\d\z)/) { "#{($1.to_i + 1).to_s.rjust(2, '0')}" }
      end
      name
    end

    def sibling_hostnames
      @layer.instances.map(&:hostname)
    end

    def hostname_unique?(name)
      !sibling_hostnames.include?(name)
    end

    def verify_ami_id(instance, options={})
      if options[:create_fresh]
        ami_id = select_ami_id
      else
        if @layer.ami_id
          ami_id = @layer.ami_id
        else
          puts "\nCurrent AMI id is #{instance.ami_id}"

          if ask_for_overriding_permission("AMI ID", true)
            ami_id = select_ami_id
          else
            ami_id = instance.ami_id
          end
        end
      end

      ami_id
    end

    def select_ami_id
      instances = @opsworks.describe_instances(stack_id: @stack.id).instances
      ami_ids = instances.collect { |i| i.ami_id }.uniq
      ami_ids << "Provide a different AMI ID."
      ami_id = ask_for_possible_options(ami_ids, "AMI ID")

      if ami_id == "Provide a different AMI ID."
        ami_id = ask_for_new_option('AMI ID')
      end

      @layer.ami_id = ami_id
    end

    def verify_agent_version(instance, options={})
      if options[:create_fresh]
        agent_version = select_agent_version
      else
        if @layer.agent_version
          agent_version = @layer.agent_version
        else
          puts "\nCurrent agent version is #{instance.agent_version}"

          if ask_for_overriding_permission("agent version", true)
            agent_version = select_agent_version
          else
            agent_version = instance.agent_version
          end
        end
      end

      agent_version
    end

    def select_agent_version
      agents = @opsworks.describe_agent_versions(stack_id: @stack.id).agent_versions
      version_ids = agents.collect { |i| i.version }.uniq
      agent_version = ask_for_possible_options(version_ids, "agent version")
      @layer.agent_version = agent_version
    end

    def verify_subnet_id(instance, options={})
      if options[:create_fresh]
        subnet_id = select_subnet_id
      else
        if @layer.subnet_id
          subnet_id = @layer.subnet_id
        else
          current_subnet = Aws::EC2::Subnet.new(id: instance.subnet_id)
          subnet_name = find_subnet_name(current_subnet)
          puts "\nCurrent subnet ID is \"#{subnet_name}\" #{current_subnet.availability_zone} (#{instance.subnet_id})"

          if ask_for_overriding_permission("subnet ID", true)
            subnet_id = select_subnet_id
          else
            subnet_id = instance.subnet_id
          end
        end
      end

      subnet_id
    end

    def select_subnet_id
      ec2_subnets = @ec2.describe_subnets.subnets
      subnets = []

      ec2_subnets.each do |subnet|
        if subnet.vpc_id == @stack.vpc_id
          subnet_name = find_subnet_name(subnet)
          zone_name = subnet.availability_zone
          subnet_id = subnet.subnet_id
          subnets << "\"#{subnet_name}\" #{zone_name} (#{subnet_id})"
        end
      end

      subnets = subnets.sort
      subnet_id = ask_for_possible_options(subnets, "subnet ID")
      subnet_id = subnet_id.scan(/(subnet-[a-z0-9]*)/).first.first if subnet_id

      @layer.subnet_id = subnet_id
      subnet_id
    end

    def find_subnet_name(subnet)
      tags = subnet.tags
      tag = nil
      tags.each { |t| tag = t if t.key == 'Name' }
      tag.value if tag
    end

    def verify_instance_type(instance, options={})
      puts "\nCurrent instance type is #{instance.instance_type}"
      rewriting = ask_for_overriding_permission("instance type", false)
      instance_type = rewriting ? ask_for_new_option('instance type') : instance.instance_type
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

    def create_new_clone(original_instance, new_instance_hostname, instance_type, ami_id, agent_version, subnet_id)
      new_instance = @opsworks.create_instance({
        stack_id: original_instance.stack_id, # required
        layer_ids: original_instance.layer_ids, # required
        instance_type: instance_type, # required
        auto_scaling_type: original_instance.auto_scaling_type, # accepts load, timer
        hostname: new_instance_hostname,
        os: original_instance.os,
        ami_id: ami_id,
        ssh_key_name: original_instance.ssh_key_name,
        # availability_zone: self.availability_zone,
        subnet_id: subnet_id,
        virtualization_type: original_instance.virtualization_type,
        architecture: original_instance.architecture, # accepts x86_64, i386
        root_device_type: original_instance.root_device_type, # accepts ebs, instance-store
        install_updates_on_boot: original_instance.install_updates_on_boot,
        #ebs_optimized: original_instance.ebs_optimized,
        agent_version: agent_version,
        tenancy: original_instance.tenancy,
      })
      
      new_manageable_instance = ManageableInstance.new(@layer, @stack, @opsworks, @ec2)
      new_manageable_instance.instance_id = new_instance.instance_id
      @layer.add_new_instance(new_instance.instance_id)
      puts "\nNew instance #{new_instance_hostname} has been created: #{new_instance.instance_id}"
      new_manageable_instance
    end

    def create_new_instance(instance, new_instance_hostname, instance_type, ami_id, agent_version, subnet_id)
      new_instance = @opsworks.create_instance({
        stack_id: @stack.id, # required
        layer_ids: [@layer.layer_id], # required
        instance_type: instance_type, # required
        hostname: new_instance_hostname,
        ami_id: ami_id,
        subnet_id: subnet_id,
        agent_version: agent_version,
        os: instance.os || 'Custom'
      })

      new_manageable_instance = ManageableInstance.new(@layer, @stack, @opsworks, @ec2)
      new_manageable_instance.instance_id = new_instance.instance_id
      @layer.add_new_instance(new_instance.instance_id)
      puts "New instance #{new_instance_hostname} has been created: #{new_instance.instance_id}"
      new_manageable_instance
    end

    def start_new_instance(new_manageable_instance)
      if ask_to_start_instance
        @opsworks.start_instance(instance_id: new_manageable_instance.instance_id)
        puts "\nNew instance is starting…"
        add_tags(new_manageable_instance)
      end
    end

    def define_tag
      tag_key = ask_for_new_option('tag name')
      tag_value = ask_for_new_option('tag value')
      { key: tag_key, value: tag_value }
    end

    def add_tags(new_manageable_instance, options={})
      raise ArgumentError, 'The instance must be running to add tags' if options[:add_tags_mode] && new_manageable_instance.status != "online"

      if options[:add_tags_mode] || ask_to_add_tags
        tags = []

        tag_count.times do
          tags << define_tag
        end

        new_manageable_instance.add_tags(tags)
      end
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

    def gather_eip_information
      eip_information = []

      @stack.eips.each do |eip|
        instance_id = eip.instance_id
        instance = @opsworks.describe_instances(instance_ids: [instance_id]).instances.first
        instance_name = instance.hostname
        layer_id = instance.layer_ids.first
        layer = @opsworks.describe_layers(layer_ids: [layer_id]).layers.first
        layer_name = layer.name
        eip_information << { eip: eip, ip_address: eip.ip, instance_name: instance_name, layer_id: layer_id }
      end

      eip_information
    end

    def ask_which_eip_to_move(eip_information)
      puts "\nHere are all of the EIPs for this stack:"
      eip_information.each_with_index { |h, index| puts "#{index.to_i + 1}) #{h[:ip_address]} connected to #{h[:instance_name]}" }
      eip_index = @cli.ask("Which EIP would you like to move?\n", Integer) { |q| q.in = 1..eip_information.length.to_i } - 1
      eip_information[eip_index]
    end

    def ask_which_target_instance(moveable_eip)
      puts "\nHere are all of the instances in the current instance's layer:"
      instances = @opsworks.describe_instances(layer_id: moveable_eip[:layer_id]).instances
      instances = instances.select { |instance| instance.elastic_ip.nil? && instance.auto_scaling_type.nil? }
      instances.each_with_index { |instance, index| puts "#{index.to_i + 1}) #{instance.status} - #{instance.hostname}" }
      instance_index = @cli.ask("What is your target instance?\n", Integer) { |q| q.in = 1..instances.length.to_i } - 1
      instances[instance_index].instance_id
    end
  end
end
