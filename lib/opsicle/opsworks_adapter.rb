class Opsicle::OpsworksAdapter
  attr_reader :client

  def initialize(opsicle_client)
    @client = opsicle_client.opsworks
  end

  def stack(stack_id)
    client.describe_stacks(stack_ids: [ stack_id ]).stacks.first
  end

  def layers(stack_id)
    client.describe_layers(stack_id: stack_id).layers
  end

  def layer(layer_id)
    client.describe_layers(layer_ids: [ layer_id ]).layers.first
  end

  def instances_by_stack(stack_id)
    client.describe_instances(stack_id: stack_id).instances
  end

  def instances_by_layer(layer_id)
    client.describe_instances(layer_id: layer_id).instances
  end

  def instance(instance_id)
    client.describe_instances(instance_ids: [ instance_id ]).instances.first
  end

  def elastic_ips(stack_id)
    client.describe_elastic_ips(stack_id: stack_id).elastic_ips
  end

  def associate_elastic_ip(elastic_ip, target_instance_id)
    client.associate_elastic_ip(
      elastic_ip: elastic_ip,
      instance_id: target_instance_id
    )
  end

  def start_instance(instance_id)
    client.start_instance(instance_id: instance_id)
  end

  def stop_instance(instance_id)
    client.stop_instance(instance_id: instance_id)
  end

  def delete_instance(instance_id)
    client.delete_instance(instance_id: instance_id)
  end
end
