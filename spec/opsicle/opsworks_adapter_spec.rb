describe Opsicle::OpsworksAdapter do
  let(:aws_opsworks_client) do
    double(:aws_opsworks_client,
      describe_layers: double(:layers, layers: []),
      start_instance: :started,
      stop_instance: :stopped,
      delete_instance: :deleted
    )
  end
  let(:client) { double(:client, opsworks: aws_opsworks_client) }

  subject { described_class.new(client) }

  describe "#get_layers" do
    let(:get_layers) { subject.get_layers(:stack_id) }

    it "should gather an array of layers for this opsworks client" do
      expect(get_layers).to be_empty
    end
  end

  describe "#start_instance" do
    it "should call start_instance on the opsworks client" do
      expect(subject.start_instance(:instance_id)).to eq(:started)
    end
  end

  describe "#stop_instance" do
    it "should call stop_instance on the opsworks client" do
      expect(subject.stop_instance(:instance_id)).to eq(:stopped)
    end
  end

  describe "#delete_instance" do
    it "should call delete_instance on the opsworks client" do
      expect(subject.delete_instance(:instance_id)).to eq(:deleted)
    end
  end
end
