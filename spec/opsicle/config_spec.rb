require "spec_helper"
require "opsicle"

module Opsicle
  describe Config do
    subject { Config.new }
    context "with a valid config" do
      before do
        allow(File).to receive(:exist?).with(File.expand_path '~/.aws/credentials').and_return(true)
        allow(File).to receive(:exist?).with('./.opsicle').and_return(true)
        allow(File).to receive(:exist?).and_return(true)
        allow(YAML).to receive(:load_file).with('./.opsicle').and_return({'derp' => { 'app_id' => 'app', 'stack_id' => 'stack' }})
      end
      before :each do
        subject.configure_aws_environment!('derp')
      end

      context "#opsworks_config" do
        it "should contain stack_id" do
          expect(subject.opsworks_config).to have_key(:stack_id)
        end

        it "should contain app_id" do
          expect(subject.opsworks_config).to have_key(:app_id)
        end
      end

      context "#aws_credentials" do
        it "should return aws credentials" do
          mfa_devices = double('mfa_devices', mfa_devices: [])
          client = double('iam_client', list_mfa_devices: mfa_devices)
          allow(Aws::IAM::Client).to receive(:new).and_return(client)
          coffee_types = {:coffee => "cappuccino", :beans => "arabica"}
          allow(coffee_types).to receive('set?').and_return(true)
          allow(Aws.config).to receive(:update).with({profile: 'derp', credentials: coffee_types})
          allow(Aws::SharedCredentials).to receive(:new).and_return(coffee_types)
          expect(subject.aws_credentials).to eq(coffee_types)
        end

        it "should suport configuarable profile name" do
          allow(YAML).to receive(:load_file).with('./.opsicle').and_return({'derp' => { 'app_id' => 'app', 'stack_id' => 'stack', 'profile_name' => 'tacos' }})
          mfa_devices = double('mfa_devices', mfa_devices: [])
          client = double('iam_client', list_mfa_devices: mfa_devices)
          allow(Aws::IAM::Client).to receive(:new).and_return(client)
          coffee_types = {:coffee => "cappuccino", :beans => "arabica"}
          allow(coffee_types).to receive('set?').and_return(true)
          allow(Aws.config).to receive(:update).with({profile: 'tacos', credentials: coffee_types})
          allow(Aws::SharedCredentials).to receive(:new).with(profile_name: 'tacos').and_return(coffee_types)
          expect(subject.aws_credentials).to eq(coffee_types)
        end
      end

      context "#configure_aws_environment!" do
        it "should return the environment as a symbol" do
          expect(subject.configure_aws_environment!("environment")).to eq(:environment)
        end
      end
    end

    context "missing configs" do
      before do
        allow(File).to receive(:exist?).with('./.opsicle').and_return(false)
      end

      context "#opsworks_config" do
        it "should gracefully raise an exception if no .fog file was found" do
          expect {subject.opsworks_config}.to raise_exception(Config::MissingConfig)
        end
      end
    end

    context "singleton support" do
      it "should return a single instance" do
        expect(Config.instance).to eq(Config.instance)
      end
    end
  end
end
