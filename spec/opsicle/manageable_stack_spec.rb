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

  let(:opsworks_adapter) do
    double(:opsworks_adapter,
      elastic_ips: true,
      instances_by_stack: [deleteable_instance, stoppable_instance],
      associate_elastic_ip: true,
      stack: double(:stack, vpc_id: "123")
    )
  end
  let(:stack_id) { '123' }
  let(:layer) { double(:layer, layer_id: "456") }
  
  subject { described_class.new(stack_id, opsworks_adapter) }

  describe "#get_eips" do
    let(:eips) { subject.get_eips }

    it "should call opsworks adapter to get a list of EIPs" do
      expect(eips).to eq(true)
    end
  end

  describe "#transfer_eip" do
    let(:transfer) { subject.transfer_eip({ip_address: true}, "target_instance_id") }

    it "should call opsworks adapter to get transfer an EIP" do
      expect(transfer).to eq(true)
    end
  end

  describe "#instances" do
    let(:instances) { subject.instances }

    it "should call opsworks adapter get a list of instances" do
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
