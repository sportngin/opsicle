require "spec_helper"
require "opsicle"

module Opsicle
  describe Update do
    subject { Update.new("env", "type") }
    let(:client) { double }
    let(:env) { "env" }
    let(:type) { "type" }
    let(:values) { { :foo => "bar" } }

    before do
      allow(Client).to receive(:new).with('env') { client }
      allow(client).to receive_message_chain("config.opsworks_config.[]") { 123 }
    end

    context "#execute" do
      it "should update and print results" do
        allow(subject).to receive(:describe) { "tacos" }
        expect(subject).to receive(:print).with("tacos", "tacos")
        api_opts = values.merge(:type_id => 123)
        expect(client).to receive(:api_call).with("update_type", api_opts)
        subject.execute(values, api_opts)
      end
    end

    context "#describe" do
      it "should return data for type" do
        expect(client).to receive(:api_call).with("describe_types", :type_ids => [123]).and_return(:types => [])
        subject.describe
      end
    end

    context "#update" do
      it "should update values for type" do
        api_opts = values.merge(:type_id => 123)
        expect(client).to receive(:api_call).with("update_type", api_opts)
        subject.update(values)
      end
    end

    context "#print" do
      it "should print no changes without table" do
        allow(Hashdiff).to receive(:diff) { [] }
        expect(Output).to receive(:say).with("Changes: 0") { nil }
        expect(Output).to_not receive(:terminal)
        subject.print(nil, nil)
      end
      it "should print changes with table" do
        allow(Hashdiff).to receive(:diff) { [%w[- nyan 1], %w[+ cat 2],%w[~ taco 3 4]] }
        expect(Output).to receive(:say).with("Changes: 3") { nil }
        allow(Output).to receive_message_chain("terminal.say")
        allow(Output).to receive_message_chain("terminal.color")
        subject.print(nil, nil)
      end
    end

    context "#format_diff" do
      let(:diff) { [%w[- nyan 1], %w[+ cat 2],%w[~ taco 3 4]] }
      let(:formatted_diff) {
        [%w[r- rnyan r1 r], %w[a+ acat a a2], %w[m~ mtaco m3 m4]]
      }

      it "should align columns and colorize" do
        allow(Output).to receive(:format).with(anything, :removal) { |arg| "r#{arg}"}
        allow(Output).to receive(:format).with(anything, :addition) { |arg| "a#{arg}"}
        allow(Output).to receive(:format).with(anything, :modification) { |arg| "m#{arg}"}
        expect(subject.format_diff(diff)).to eq(formatted_diff)
      end
    end
  end
end
