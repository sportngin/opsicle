class Opsicle::OpsworksAdapter
  attr_reader :client

  def initialize(client)
    @client = client.opsworks
  end

  def get_layers(stack_id)
    client.describe_layers(stack_id: stack_id).layers
  end

  def start_instance(instance_id)
    client.start_instance(instance_id: instance_id)
  end

  def delete_instance(instance_id)
    client.delete_instance(instance_id: instance_id)
  end
end
