require "spec_helper"
require "opsicle"
require "opsicle/deployment"

describe Opsicle::Monitor::App do

  before do
    @screen = double(
      :close     => nil,
      :refresh   => nil,
      :next_key  => nil,
      :refresh_spies => nil,
      :missized? => nil
    )

    @client = double

    allow(Opsicle::Monitor::Screen).to receive(:new).and_return(@screen)
    allow(Opsicle::Client).to receive(:new).and_return(@client)

    @app = Opsicle::Monitor::App.new("staging", {})
  end

  describe "#initialize" do

    it "sets status not-running" do
      expect(@app.running).to equal(false)
    end

    it "sets status not-restarting" do
      expect(@app.restarting).to equal(false)
    end

    context "when the app is montoring a deploy" do
      before do
        @app = Opsicle::Monitor::App.new("staging", {:deployment_id => 123})
      end

      it "set the deployment_id" do
        expect(@app.deployment_id).to equal(123)
      end

      it "assigns a deploy" do
        expect(@app.deploy).to be_an_instance_of(Opsicle::Deployment)
      end
    end

  end

  describe "#restart" do
    before do
      @app.instance_variable_set(:@restarting, false)
    end

    it "sets status restarting" do
      @app.restart

      expect(@app.restarting).to equal(true)
    end
  end

  describe "#do_command" do
    before do
      @app.instance_variable_set(:@running, true)
      @app.instance_variable_set(:@screen, @screen)
    end

    it "<d> switches to Deployments panel" do
      expect(@screen).to receive(:panel_main=).with(:deployments)

      @app.do_command('d')
    end

    it "<h> switches to Help panel" do
      expect(@screen).to receive(:panel_main=).with(:help)

      @app.do_command('h')
    end
  end

  describe "#deploy_running?" do
    before do
      deployment = double("deployment", :running? => true)
      @app = Opsicle::Monitor::App.new("staging", {:deployment_id => 123})
      @app.instance_variable_set :@deploy, double("deploy", :deployment => deployment)
    end

    it "reloads the status" do
      expect(@app.deploy).to receive(:deployment).with(:reload => true)
      @app.send(:deploy_running?)
    end

    context "if the deploy is still running" do
      it "returns true" do
        expect(@app.send(:deploy_running?)).to be_truthy
      end
    end

    context "if the deploy finished" do
      before do
        deployment = double("deployment", :running? => false)
        @app.instance_variable_set :@deploy, double("deploy", :deployment => deployment)
      end

      it "returns false" do
        expect(@app.send(:deploy_running?)).to be_falsey
      end
    end
  end

end
