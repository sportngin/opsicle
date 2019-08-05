describe Opsicle::MoveEip do
  let(:old_eip) { 'old_eip' }
  let(:target_instance) { 'target_instance' }
  let(:opsworks_eip) { double(:eip, ip: "123", instance_id: "1234") }
  let(:opsworks_stack) { double(:stack, id: "1234", vpc_id: "21") }
  let(:config) { double(:config, opsworks_config: {stack_id: "123"}) }
  let(:opsicle_client) { double(:client, config: config, opsworks: opsworks_client) }

  let(:opsworks_client) do
    double(:opsworks_client,
      associate_elastic_ip: true,
      describe_stacks: double(stack: [opsworks_stack])
    )
  end

  let(:opsworks_adapter) do
    double(:opsworks_adapter,
      client: opsworks_client,
      stack: opsworks_stack,
      elastic_ips: [opsworks_eip, opsworks_eip],
      instance: double(hostname: 'hostname', layer_ids: ['layer_id']),
      layer: double(name: 'layer_name')
    )
  end

  let(:eip_inquiry) do
    double(:eip_inquiry,
      which_eip_should_move: { ip_address: old_eip },
      which_instance_should_get_eip: target_instance
    )
  end

  before do
    allow(Opsicle::Client).to receive(:new).with("staging").and_return(opsicle_client)
    allow(Opsicle::OpsworksAdapter).to receive(:new).and_return(opsworks_adapter)
    allow(Opsicle::Questionnaire::EipInquiry).to receive(:new).and_return(eip_inquiry)
  end

  subject { described_class.new("staging") }

  describe "#execute" do
    it "should make an API call to opsworks to change the EIP" do
      expect(opsworks_adapter).to receive(:associate_elastic_ip).with(old_eip, target_instance)
      subject.execute
    end
  end
end
