module Opsicle
<<<<<<< HEAD:lib/opsicle/manageable_stack.rb
  class ManageableStack
    attr_accessor :id, :opsworks, :stack, :vpc_id
=======
  class CloneableStack
    attr_accessor :id, :opsworks, :stack, :vpc_id, :eips, :cli
>>>>>>> origin/master:lib/opsicle/cloneable_stack.rb

    def initialize(stack_id, opsworks, cli=nil)
      self.id = stack_id
      self.opsworks = opsworks
      self.cli = cli
      self.stack = get_stack
      self.vpc_id = self.stack.vpc_id
      self.eips = nil
    end

    def get_stack
      @opsworks.describe_stacks({ :stack_ids => [self.id.to_s] }).stacks.first
    end

    def get_eips
      self.eips = @opsworks.describe_elastic_ips(stack_id: self.id.to_s).elastic_ips
    end

    def gather_eip_information
      eip_information = []

      @eips.each do |eip|
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
      instances.each_with_index { |instance, index| puts "#{index.to_i + 1}) #{instance.status} - #{instance.hostname}" }
      instance_index = @cli.ask("What is your target instance?\n", Integer) { |q| q.in = 1..instances.length.to_i } - 1
      instances[instance_index].instance_id
    end

    def transfer_eip(moveable_eip, target_instance_id)
      @opsworks.associate_elastic_ip({ elastic_ip: moveable_eip[:ip_address], instance_id: target_instance_id })
      puts "\nEIP #{moveable_eip[:ip_address]} was moved to instance #{target_instance_id}"
    end

    def move_eip
      get_eips
      eip_information = gather_eip_information
      moveable_eip = ask_which_eip_to_move(eip_information)
      target_instance_id = ask_which_target_instance(moveable_eip)
      transfer_eip(moveable_eip, target_instance_id)
    end

    def instances
      @opsworks.describe_instances(stack_id: self.id).instances
    end

    def deleteable_instances
      instances.select{|instance| instance.auto_scaling_type.nil?  && instance.status == "stopped"}
    end

    def stoppable_states
      %w(start_failed stop_failed online running_setup setup_failed booting rebooting)
    end

    def stoppable_instances
      instances.select{|instance| instance.elastic_ip.nil?  && stoppable_states.include?(instance.status)}
    end
  end
end
