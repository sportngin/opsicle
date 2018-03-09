describe Opsicle::OpsworksAdapter do
  let(:aws_opsworks_client) do
    double(
     :aws_opsworks_client,
     describe_layers: double(:layers, layers: []),
     start_instance: true
    )
  end
  let(:client) { double(:client, opsworks: aws_opsworks_client) }

  subject { described_class.new(client) }

  describe "#get_layers" do
    let(:get_layers) { subject.get_layers(:stack_id) }

    it "should gather an array of layers for this opsworks client" do
      expect(get_layers).to be_empty
    end

    it "should call describe_layers on the opsworks client" do
      expect(aws_opsworks_client).to receive(:describe_layers).with(stack_id: :stack_id)
      get_layers
    end
  end

  describe "#start_instance" do
    it "should call start_instance on the opsworks client" do
      expect(aws_opsworks_client).to receive(:start_instance).with(instance_id: :instance_id)
      subject.start_instance(:instance_id)
    end
  end
end
