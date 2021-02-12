require 'terminal-table'

module Opsicle
  class ListInstances
    attr_reader :client

    def initialize(environment)
      @client = Client.new(environment)
      @stack = Stack.new(@client)
    end

    def execute(options={})
      print(get_instances)
    end

    def get_instances
      Opsicle::Instances.new(client).data
    end

    def print(instances)
      puts Terminal::Table.new(
        headings: [
          'Hostname',
          'Size',
          'Layers',
          'Status',
          'Public IP',
          'Private IP',
          'Zone'
        ],
        rows: instance_data(instances)
      )
    end

    def instance_data(instances)
      instances
        .sort { |a,b| a[:hostname] <=> b[:hostname] }
        .map do |instance|
          [
            instance[:hostname],
            instance[:instance_type],
            layer_names(instance),
            instance[:status],
            Opsicle::Instances::pretty_ip(instance),
            Opsicle::Instances::private_ip(instance),
            instance[:availability_zone]
          ]
        end
    end

    def layer_names(instance)
      instance[:layer_ids].map{ |layer_id| @stack.layer_name(layer_id) }.join(", ")
    end

  end
end
