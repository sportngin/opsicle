describe Opsicle::OpsworksAdapter do
  let(:aws_opsworks_client) do
    double(:aws_opsworks_client,
      describe_stacks: double(:stacks, stacks: [:stack_one]),
      describe_layers: double(:layers, layers: [:layer_one]),
      describe_instances: double(:instances, instances: [:instance_one]),
      describe_elastic_ips: double(:eips, elastic_ips: []),
      associate_elastic_ip: :associated_eip,
      start_instance: :started,
      stop_instance: :stopped,
      delete_instance: :deleted
    )
  end
  let(:client) { double(:client, opsworks: aws_opsworks_client) }

  subject { described_class.new(client) }

  describe "#stack" do
    let(:stack) { subject.stack(:stack_id) }

    it "should return the stack in question" do
      expect(stack).to eq(:stack_one)
    end
  end

  describe "#layers" do
    let(:layers) { subject.layers(:stack_id) }

    it "should gather an array of layers for this opsworks client" do
      expect(layers).to eq([:layer_one])
    end
  end

  describe "#layer" do
    let (:layer) { subject.layer(:layer_id) }

    it "should get the layer in question" do
      expect(layer).to eq(:layer_one)
    end
  end

  describe "#instances_by_stack" do
    let (:instances) { subject.instances_by_stack(:stack_id) }

    it "should get a list of instances in the stack" do
      expect(instances).to eq([:instance_one])
    end
  end

  describe "#instances_by_layer" do
    let (:instances) { subject.instances_by_layer(:layer_id) }

    it "should get a list of instances in the_layer" do
      expect(instances).to eq([:instance_one])
    end
  end

  describe "#instance" do
    let (:instance) { subject.instance(:instance_id) }

    it "should get the instance in question" do
      expect(instance).to eq(:instance_one)
    end
  end

  describe "#elastic_ips" do
    let (:eips) { subject.elastic_ips(:stack_id) }

    it "should get a list of the EIPs in the stack" do
      expect(eips).to be_empty
    end
  end

  describe "#associate_elastic_ip" do
    let (:associated) { subject.associate_elastic_ip(:eip, :target_instance_id) }

    it "should get a list of the EIPs in the stack" do
      expect(associated).to be(:associated_eip)
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
