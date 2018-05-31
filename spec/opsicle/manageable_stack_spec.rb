describe Opsicle::ManageableStack do
  let(:deleteable_instance) do
    double(:deleteable_instance,
      auto_scaling_type: nil,
      status: "stopped",
      layer_ids: ["456"],
      elastic_ip: nil
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

  let(:eip) do
    double(:eip,
      instance_id: "123",
      ip: "ip-123"
    )
  end

  let(:opsworks_adapter) do
    double(:opsworks_adapter,
      instance: double(:instance, hostname: "example-hostname", layer_ids: ["id1", "id2"]),
      layer: double(:layer, name: "layer-name"),
      elastic_ips: [eip],
      instances_by_stack: [deleteable_instance, stoppable_instance],
      associate_elastic_ip: true,
      stack: double(:stack, vpc_id: "123")
    )
  end
  let(:stack_id) { '123' }
  let(:layer) { double(:layer, layer_id: "456") }
  
  subject { described_class.new(stack_id, opsworks_adapter) }

  describe "#gather_eips" do
    let(:eips) { subject.gather_eips }

    it "should properly find and format EIPs" do
      expect(eips).to eq([{eip: eip, ip_address: "ip-123", instance_name: "example-hostname", layer_id: "id1"}])
    end

    it "should call opsworks_adapter to gather EIPs" do
      expect(opsworks_adapter).to receive(:elastic_ips)
      subject.gather_eips
    end
  end

  describe "#transfer_eip" do
    let(:transfer) { subject.transfer_eip({ip_address: true}, "target_instance_id") }

    it "should properly transfer the EIP" do
      expect(transfer).to eq(true)
    end

    it "should call opsworks_adapter to transfer EIP" do
      expect(opsworks_adapter).to receive(:associate_elastic_ip)
      subject.transfer_eip({ip_address: true}, "target_instance_id")
    end
  end

  describe "#instances" do
    let(:instances) { subject.instances }

    it "should properly gather a list of instances" do
      expect(instances).to eq([deleteable_instance, stoppable_instance])
    end

    it "should call opsworks_adapter to get a list of instances" do
      expect(opsworks_adapter).to receive(:instances_by_stack)
      subject.instances
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
