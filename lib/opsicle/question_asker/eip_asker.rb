module Opsicle
  module QuestionAsker
    class EipAsker
      attr_accessor :opsworks_adapter, :cli

      def initialize(options)
        @opsworks_adapter = options[:opsworks_adapter]
        @cli = options[:highline_client]
      end

      def which_eip_should_move(eip_information)
        puts "\nHere are all of the EIPs for this stack:"
        eip_information.each_with_index { |h, index| puts "#{index.to_i + 1}) #{h[:ip_address]} connected to #{h[:instance_name]}" }
        eip_index = @cli.ask("Which EIP would you like to move?\n", Integer) { |q| q.in = 1..eip_information.length.to_i } - 1
        eip_information[eip_index]
      end

      def which_instance_should_get_eip(moveable_eip)
        puts "\nHere are all of the instances in the current instance's layer:"
        instances = @opsworks_adapter.instances_by_layer(moveable_eip[:layer_id])
        instances = instances.select { |instance| instance.elastic_ip.nil? && instance.auto_scaling_type.nil? }
        instances.each_with_index { |instance, index| puts "#{index.to_i + 1}) #{instance.status} - #{instance.hostname}" }
        instance_index = @cli.ask("What is your target instance?\n", Integer) { |q| q.in = 1..instances.length.to_i } - 1
        instances[instance_index].instance_id
      end
    end
  end
end
