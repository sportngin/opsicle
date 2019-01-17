module Opsicle
  module Questionnaire
    class EipInquiry
      attr_accessor :opsworks_adapter, :cli

      def initialize(options)
        self.opsworks_adapter = options[:opsworks_adapter]
        self.cli = options[:highline_client]
      end

      def which_eip_should_move(eip_information)
        puts "\nHere are all of the EIPs for this stack:"
        print_current_eips(eip_information)
        eip_index = ask_eip_question("Which EIP would you like to move?\n", eip_information)
        eip_information[eip_index]
      end

      def which_instance_should_get_eip(moveable_eip)
        puts "\nHere are all of the instances in the current instance's layer:"
        instances = get_potential_target_instances(moveable_eip)
        check_for_printable_items!(instances)
        print_potential_target_instances(instances)
        instance_index = ask_eip_question("What is your target instance?\n", instances)
        instances[instance_index].instance_id
      end

      def ask_eip_question(prompt, choices)
        @cli.ask(prompt, Integer) { |q| q.in = 1..choices.length.to_i } - 1
      end
      private :ask_eip_question

      def print_current_eips(eip_information)
        eip_information.each_with_index { |eip, index| puts "#{index.to_i + 1}) #{eip[:ip_address]} connected to #{eip[:instance_name]}" }
      end
      private :print_current_eips

      def print_potential_target_instances(instances)
        instances.each_with_index { |instance, index| puts "#{index.to_i + 1}) #{instance.status} - #{instance.hostname}" }
      end
      private :print_potential_target_instances

      def get_potential_target_instances(moveable_eip)
        instances = @opsworks_adapter.instances_by_layer(moveable_eip[:layer_id])
        instances.select do |instance|
          instance.elastic_ip.nil? &&
          instance.auto_scaling_type.nil? &&
          instance.status == "online"
        end
      end
      private :get_potential_target_instances

      def check_for_printable_items!(instances)
        if instances.empty? # instances is the list of instances that an eip can be moved to
          raise StandardError, "You cannot move an EIP when there's only one instance running."
        end
      end
      private :check_for_printable_items!
    end
  end
end
