describe Opsicle::Ec2Adapter do
  let(:aws_ec2_client) do
    double(
     :aws_ec2_client,
     describe_subnets: double(:subnets, subnets: []),
     create_tags: :successful_response
    )
  end
  let(:client) { double(:client, ec2: aws_ec2_client) }

  subject { described_class.new(client) }

  describe "#get_subnets" do
    it "should gather an array of subnets for this ec2 client" do
      expect(subject.get_subnets).to be_empty
    end
  end

  describe "#tag_instance" do
    it "should call to create a tag on an instance" do
      expect(subject.tag_instance(:instance_id, [1, 2, 3])).to eq(:successful_response)
    end
  end
end
