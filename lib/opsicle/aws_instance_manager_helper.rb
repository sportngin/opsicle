module Opsicle
  module AwsInstanceManagerHelper
    ##########################
    ### Moving around EIPs ###
    ##########################
    
    def ask_which_eip_to_move(eip_information)
      puts "\nHere are all of the EIPs for this stack:"
      eip_information.each_with_index { |h, index| puts "#{index.to_i + 1}) #{h[:ip_address]} connected to #{h[:instance_name]}" }
      eip_index = @cli.ask("Which EIP would you like to move?\n", Integer) { |q| q.in = 1..eip_information.length.to_i } - 1
      eip_information[eip_index]
    end

    def ask_which_target_instance(moveable_eip)
      puts "\nHere are all of the instances in the current instance's layer:"
      instances = @opsworks_adapter.instances_by_layer(moveable_eip[:layer_id])
      instances = instances.select { |instance| instance.elastic_ip.nil? && instance.auto_scaling_type.nil? }
      instances.each_with_index { |instance, index| puts "#{index.to_i + 1}) #{instance.status} - #{instance.hostname}" }
      instance_index = @cli.ask("What is your target instance?\n", Integer) { |q| q.in = 1..instances.length.to_i } - 1
      instances[instance_index].instance_id
    end

    def gather_eip_information(eips)
      eip_information = []

      eips.each do |eip|
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
  end
end
