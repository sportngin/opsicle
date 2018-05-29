describe Opsicle::ManageableStack do
  let(:opsworks_adapter) { double('opsworks_adapter', :elastic_ips => true, :transfer_eip => true) }
  let(:stack_id) { '123' }
  let(:client) { double(:client, stack_id: stack_id, opsworks_adapter: opsworks_adapter) }
  subject { described_class.new(client) }

  describe "#get_eips" do
    let(:eips) { subject.get_eips }

    it "should call opsworks adapter to get a list of EIPs" do
      expect(eips).to eq(true)
    end
  end

  describe "#transfer_eip" do
    let(:transfer) { subject.transfer_eip }

    it "should call opsworks adapter to get transfer an EIP" do
      expect(transfer).to eq(true)
    end
  end
end
