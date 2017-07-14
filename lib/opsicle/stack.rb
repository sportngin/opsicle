module Opsicle
  class Stack

    def initialize(client)
      @client = client
    end

    def stack_summary(options={})
      # Only call the API again if you need to
      @stack_summary = nil if options[:reload]
      @deployment ||= @client.api_call('describe_stack_summary',
                                       :stack_id => @client.config.opsworks_config[:stack_id]
                                      )[:stack_summary]
    end
    private :stack_summary

    def name
      stack_summary[:name]
    end

    def stack_id
      stack_summary[:stack_id]
    end

    def layers
      @layers ||= @client.api_call('describe_layers', stack_id: @client.config.opsworks_config[:stack_id])[:layers]
    end

    def layer_name(layer_id)
      layers.detect{ |layer| layer[:layer_id] == layer_id }[:shortname]
    end

  end
end
