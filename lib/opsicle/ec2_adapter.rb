class Opsicle::Ec2Adapter
  attr_reader :client

  def initialize(opsicle_client)
    @client = opsicle_client.ec2
  end

  def get_subnets
    client.describe_subnets.subnets
  end

  def tag_instance(ec2_instance_id, tags)
    client.create_tags(resources: [ ec2_instance_id ], tags: tags)
  end
end
