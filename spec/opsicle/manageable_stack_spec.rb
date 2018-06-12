describe Opsicle::ManageableStack do
  let(:deleteable_instance) do
    double(:deleteable_instance,
      auto_scaling_type: nil,
      status: "stopped",
      layer_ids: ["456"],
      elastic_ip: nil,
      hostname: "example-hostname"
    )
  end

  let(:stoppable_instance) do
    double(:stoppable_instance,
      elastic_ip: nil,
      status: "start_failed",
      layer_ids: ["456"],
      auto_scaling_type: nil
    )
  end

  let(:stack) do
    double(:stack,
      vpc_id: "id"
    )
  end

  let(:layer) do
    double(:layer,
      layer_id: "456",
      name: "layername"
    )
  end

  let(:eip) do
    double(:eip,
      instance_id: "123",
      ip: "ip-123",
    )
  end

  let(:client) do
    double(:client,
      opsworks: aws_opsworks_client
    )
  end

  let(:aws_opsworks_client) do
    double(:aws_opsworks_client,
      describe_stacks: double(:stacks, stacks: [stack]),
      describe_layers: double(:layers, layers: [layer]),
      describe_instances: double(:instances, instances: [deleteable_instance, stoppable_instance]),
      describe_elastic_ips: double(:eips, elastic_ips: [eip]),
      associate_elastic_ip: :associated_eip,
      start_instance: :started,
      stop_instance: :stopped,
      delete_instance: :deleted
    )
  end

  let(:opsworks_adapter) { Opsicle::OpsworksAdapter.new(client) }
  let(:stack_id) { '123' }
  
  subject { described_class.new(stack_id, opsworks_adapter) }

  describe "#eips" do
    let(:eips) { subject.eips }

    it "should properly find and format EIPs" do
      expect(eips).to eq([{eip: eip, ip_address: "ip-123", instance_name: "example-hostname", layer_id: "456"}])
    end
  end

  describe "#transfer_eip" do
    let(:transfer) { subject.transfer_eip({ip_address: true}, "target_instance_id") }

    it "should properly transfer the EIP" do
      expect(transfer).to eq(:associated_eip)
    end
  end

  describe "#instances" do
    let(:instances) { subject.instances }

    it "should properly gather a list of instances" do
      expect(instances).to eq([deleteable_instance, stoppable_instance])
    end
  end

  describe "#deleteable_instances" do
    let(:instances) { subject.deleteable_instances(layer) }

    it "should look for any instances that are deleteable" do
      expect(instances).to eq([deleteable_instance])
    end
  end

  describe "#stoppable_instances" do
    let(:instances) { subject.stoppable_instances(layer) }

    it "should look for any instances that are stoppable" do
      expect(instances).to eq([stoppable_instance])
    end
  end
end
