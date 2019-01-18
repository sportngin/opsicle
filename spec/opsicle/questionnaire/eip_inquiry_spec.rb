describe Opsicle::Questionnaire::EipInquiry do
  let(:cli) { double(:cli, ask: 1) }

  let(:online_instance_with_eip) do
    double(:instance,
      elastic_ip: true,
      auto_scaling_type: nil,
      status: "online",
      hostname: "example",
      instance_id: "instance-id"
    )
  end

  let(:online_instance_without_eip) do
    double(:instance,
      elastic_ip: nil,
      auto_scaling_type: nil,
      status: "online",
      hostname: "example",
      instance_id: "instance-id"
    )
  end

  let(:stopped_instance) do
    double(:instance,
      elastic_ip: nil,
      auto_scaling_type: nil,
      status: "stopped",
      hostname: "example",
      instance_id: "instance-id"
    )
  end

  let(:client) { double(:client, opsworks: aws_opsworks_client) }

  let(:aws_opsworks_client) do
    double(:aws_opsworks_client,
      describe_instances: double(:instances, instances: [online_instance_with_eip, online_instance_without_eip, stopped_instance])
    )
  end

  let(:opsworks_adapter) { Opsicle::OpsworksAdapter.new(client) }

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

  describe "#which_instance_should_get_eip" do
    let(:instance_response) { subject.which_instance_should_get_eip(eip_info) }

    it "should return a single instance" do
      expect(instance_response).to eq("instance-id")
    end

    context "when there are no target instances" do
      let(:online_instance_with_eip) do
        double(:instance,
          elastic_ip: true,
          auto_scaling_type: nil,
          status: "stopped",
          hostname: "example",
          instance_id: "instance-id"
        )
      end

      let(:online_instance_without_eip) do
        double(:instance,
          elastic_ip: nil,
          auto_scaling_type: nil,
          status: "stopped",
          hostname: "example",
          instance_id: "instance-id"
        )
      end

      let(:stopped_instance) do
        double(:instance,
          elastic_ip: nil,
          auto_scaling_type: nil,
          status: "stopped",
          hostname: "example",
          instance_id: "instance-id"
        )
      end

      it "should raise an error" do
        expect{subject.which_instance_should_get_eip(eip_info)}.to raise_error(StandardError)
      end
    end
  end

  describe "#check_for_printable_items" do
    context "when there are instances" do
      it "should not raise an error" do
        expect(subject.send(:check_for_printable_items!, [ 1, 2, 3 ])).to eq(nil)
      end
    end

    context "when there are no instances" do
      it "should raise an error" do
        expect{subject.send(:check_for_printable_items!, [])}.to raise_error(StandardError)
      end
    end
  end
end
