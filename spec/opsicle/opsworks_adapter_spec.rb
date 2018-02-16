require "spec_helper"
require "opsicle"
require 'gli'
require "opsicle/user_profile"

module Opsicle
  describe OpsworksAdapter do
    before do
      @layers = double('layers', layers: [])
      @aws_opsworks_client = double('aws_opsworks_client', describe_layers: @layers, start_instance: true)
      @client = double('client', opsworks: @aws_opsworks_client)
    end

    context "#get_layers" do
      it "should gather an array of layers for this opsworks client" do
        ops_layers = OpsworksAdapter.new(@client).get_layers(1234)
        expect(ops_layers).to eq([])
      end

      it "should call describe_layers on the opsworks client" do
        expect(@aws_opsworks_client).to receive(:describe_layers).with(stack_id: 1234)
        ops_layers = OpsworksAdapter.new(@client).get_layers(1234)
      end
    end

    context "#start_instance" do
      it "should call start_instance on the opsworks client" do
        expect(@aws_opsworks_client).to receive(:start_instance).with(instance_id: 1234)
        ops_layers = OpsworksAdapter.new(@client).start_instance(1234)
      end
    end
  end
end
