module Opsicle
  class Instances

    attr_accessor :client
    class << self
      attr_accessor :client
    end

    def initialize(client)
      @client = client
    end

    def data
      instances(reload: true)
    end

    def self.pretty_ip(instance)
      instance[:elastic_ip] ? "#{instance[:elastic_ip]} EIP" : instance[:public_ip]
    end

    def self.private_ip(instance)
      instance[:private_ip]
    end

    def self.find_by_ip(client, ips)
      instances = new(client).data.reject { |instance| instances_matching_ips(instance, ips) }
      instances.empty? ? nil : instances
    end

    def self.instances_matching_ips(instance, ip_addresses)
      instance_ips = [instance[:public_ip], instance[:elastic_ip], instance[:private_ip]].compact
      (ip_addresses & instance_ips).empty?
    end

    private_class_method :instances_matching_ips

    def self.find_by_eip(client)
      instances =  new(client).data.reject { |instance| instance[:elastic_ip] == nil }
      instances.empty? ? nil : instances
    end

    def instances(options={})
      # Only call the API again if you need to
      @instances = nil if options[:reload]
      @instances ||= client.api_call('describe_instances',
                                       :stack_id => client.config.opsworks_config[:stack_id]
                                      )[:instances]
    end
    private :instances

  end
end
