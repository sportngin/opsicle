module Opsicle
  class Layer

    attr_reader :id, :name

    def initialize(client, options = {})
      @client = client
      @id = options[:layer_id]
      @name = options[:layer_name]
    end

    # Public - Gets all the instance ids for a  layer
    #
    # Return - An array of instance ids
    def get_instance_ids
      client.api_call('describe_instances', layer_id: id)[:instances].map{ |s| s[:instance_id] }
    end

    # Private - Gets layer info from OpsWorks
    #
    # Return - An array of layer objects
    def self.get_info
      client.api_call('describe_layers')[:layers].map{ |layer| new(client, id: layer[:layer_id], name: layer[:shortname] )}
    end
    private_class_method :get_info

    # Public - gets all the layer ids for the given layers
    #
    # client - a new Client
    # layers - an array of layer shortnames
    #
    # Return - An array of instance ids belonging to the input layers
    def self.instance_ids(client, layers)
      @client = client
      get_info.map { |layer| instance_ids[0] if layers.includes?(layer.name) }
    end

  end
end

