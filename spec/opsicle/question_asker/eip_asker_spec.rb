describe Opsicle::QuestionAsker::EipAsker do
  let(:cli) do
    double(:cli,
      ask: 1
    )
  end

  let(:instance) do
    double(:instance,
      elastic_ip: "example-hostname",
      auto_scaling_type: ["type1", "type2"],
      status: "online",
      hostname: "example"
    )
  end

  let(:opsworks_adapter) do
    double(:opsworks_adapter,
      instances_by_layer: [instance]
    )
  end

  let(:eip_info) do
    { eip: true, ip_address: "ip-123", instance_name: "example-hostname", layer_id: "id1" }
  end
  
  subject { described_class.new(opsworks_adapter: opsworks_adapter, highline_client: cli) }

  describe "#which_eip_should_move" do
    let(:eip_response) { subject.which_eip_should_move([eip_info]) }

    it "should ask the user a question" do
      expect(cli).to receive(:ask)
      subject.which_eip_should_move([eip_info])
    end

    it "should return the EIP to move" do
      expect(eip_response).to eq(eip_info)
    end
  end
end
