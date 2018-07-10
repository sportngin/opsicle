describe Opsicle::MoveEip do
  let(:moveable_eip) do
    double(:eip,
      eip: true,
      ip_address: "123",
      instance_name: "instance-1-hostname",
      layer_id: "456"
    )
  end

  let(:eip_two) do
    double(:eip,
      eip: true,
      ip_address: "123",
      instance_name: "instance-2-hostname",
      layer_id: "456"
    )
  end

  let(:stack) do
    double(:stack,
      id: "1234",
      transfer_eip: true,
      eips: [moveable_eip, eip_two]
    )
  end
  
  let(:client) do
    double(:client,
      config: @config,
      opsworks: @opsworks,
      ec2: @ec2
    )
  end
  
  let(:eip_inquiry) do
    double(:eip_inquiry,
      which_eip_should_move: moveable_eip,
      which_instance_should_get_eip: "123"
    )
  end

  before do
    allow(Opsicle::Questionnaire::EipInquiry).to receive(:new).and_return(eip_inquiry)
    allow(Opsicle::ManageableStack).to receive(:new).and_return(stack)
  end

  subject { described_class.new("staging") }

  describe "#move_eip" do
    it "should properly transfer the EIP on the stack" do
      expect(stack).to receive(:transfer_eip)
      subject.move_eip
    end

    it "should ask for the stack's EIPs" do
      expect(stack).to receive(:eips)
      subject.move_eip
    end

    it "should call to the EIP inquiry" do
      expect(eip_inquiry).to receive(:which_eip_should_move)
      subject.move_eip
    end

    it "should call to the EIP inquiry to ask about target instances" do
      expect(eip_inquiry).to receive(:which_instance_should_get_eip)
      subject.move_eip
    end
  end
end
