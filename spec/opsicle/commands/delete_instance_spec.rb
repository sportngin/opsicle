require "spec_helper"
require "opsicle"
require 'gli'
require "opsicle/user_profile"

describe Opsicle::DeleteInstance do
  let(:config) { double(:config, opsworks_config: {stack_id: "1234"}) }
  let(:opsicle_client) { double(:client, config: config, opsworks: opsworks_client, ec2: ec2_client) }
  let(:opsworks_stack) { double(:stack, id: "1234", vpc_id: "21") }
  let(:layer1) { double(:layer, name: "layer1", layer_id: "123") }
  let(:layer2) { double(:layer, name: "layer2", layer_id: "456") }

  let(:instance1) do
    double(:instance,
      name: "instance1",
      layer_ids: [ "456" ],
      status: "stopped",
      auto_scaling_type: nil,
      instance_id: "123",
      hostname: "instance1"
    )
  end

  let(:opsworks_client) do
    double(:opsworks_client,
      associate_elastic_ip: true,
      describe_stacks: double(stack: [ opsworks_stack ]),
      describe_instances: double(instances: [ instance1 ])
    )
  end

  let(:ec2_client) { double(:ec2_client) }

  let(:opsworks_adapter) do
    double(:opsworks_adapter,
      client: opsworks_client,
      stack: opsworks_stack,
      layers: [ layer1, layer2 ],
      instances_by_stack: [ instance1 ]
    )
  end

  let(:ec2_adapter) do
    double(:ec2_adapter,
      client: ec2_client,
      stack: opsworks_stack,
      elastic_ips: []
    )
  end

  before do
    allow(Opsicle::Client).to receive(:new).with("staging").and_return(opsicle_client)
    allow(Opsicle::OpsworksAdapter).to receive(:new).and_return(opsworks_adapter)
    allow_any_instance_of(HighLine).to receive(:ask).with("Layer?\n", Integer).and_return(2)
  end

  subject { described_class.new("staging") }


  describe "#execute" do
    context "when everything works as expected" do
      before do
        allow_any_instance_of(HighLine).to receive(:ask).with("Which instances would you like to delete? (enter as a comma separated list)\n", String).and_return("1")
      end

      it "should properly ask to delete instances" do
        expect(opsworks_adapter).to receive(:delete_instance).with("123")
        subject.execute
      end
    end

    context "when an improper value is passed in as something to delete" do
      before do
        allow_any_instance_of(HighLine).to receive(:ask).with("Which instances would you like to delete? (enter as a comma separated list)\n", String).and_return("-1")
      end

      it "should properly ask to delete instances" do
        expect{subject.execute}.to raise_error(StandardError)
      end
    end

    context "when there are no deletable instances" do
      let(:instance1) do
        double(:instance,
          name: "instance1",
          layer_ids: [ "456" ],
          status: "online",
          auto_scaling_type: nil,
          instance_id: "123",
          hostname: "instance1"
        )
      end

      it "should not delete any instances" do
        expect(opsworks_adapter).not_to receive(:delete_instance)
        subject.execute
      end
    end
  end
end
