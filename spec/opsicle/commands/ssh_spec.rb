require "spec_helper"
require "opsicle"

module Opsicle
  describe SSH do
    subject { SSH.new('derp') }
    let(:client) { double(config: double(opsworks_config: {stack_id: "1234"})) }
    let(:stack) { double(client: client) }
    let(:user_profile) { double }
    before do
      allow(Client).to receive(:new).with('derp').and_return(client)
      allow(Stack).to receive(:new).with(client).and_return(stack)
      allow(UserProfile).to receive(:new).with(client).and_return(user_profile)
    end

    context "#execute" do
      before do
        allow(Output).to receive(:say)
        allow(Output).to receive(:say_verbose)
        allow(Output).to receive(:ask).and_return(2)
        allow(subject).to receive(:ssh_username) {"mrderpyman2014"}
      end

      it "executes ssh with a selected Opsworks instance IP" do
        allow(subject).to receive(:instances) {[
                                    { hostname: "host1", elastic_ip: "123.123.123.123" },
                                    { hostname: "host2", elastic_ip: "789.789.789.789" }
                                  ]}

        expect(subject).to receive(:system).with("ssh mrderpyman2014@789.789.789.789")
        subject.execute
      end

      it "executes ssh with public_ip listings as well as elastic_ip" do
        allow(subject).to receive(:instances) {[
                                    { hostname: "host1", elastic_ip: "678.678.678.678" },
                                    { hostname: "host2", public_ip: "987.987.987.987" }
                                  ]}

        expect(subject).to receive(:system).with("ssh mrderpyman2014@987.987.987.987")
        subject.execute
      end

      it "executes ssh favoring an elastic_ip over a public_ip if both exist" do
        allow(subject).to receive(:instances) {[
                                    { hostname: "host1", elastic_ip: "678.678.678.678" },
                                    { hostname: "host2", public_ip: "987.987.987.987", elastic_ip: "132.132.132.132" }
                                  ]}

        expect(subject).to receive(:system).with("ssh mrderpyman2014@132.132.132.132")
        subject.execute
      end

      it "executes ssh right away if there is only one Opsworks instance available" do
        allow(subject).to receive(:instances) {[
                                    { hostname: "host3", elastic_ip: "456.456.456.456" }
                                  ]}

        expect(subject).to receive(:system).with("ssh mrderpyman2014@456.456.456.456")
        expect(subject).not_to receive(:ask)
        subject.execute
      end

      it "executes ssh with ssh options and command" do
        allow(subject).to receive(:instances) {[
                                    { hostname: "host1", elastic_ip: "123.123.123.123" },
                                    { hostname: "host2", elastic_ip: "789.789.789.789" }
                                  ]}

        expect(subject).to receive(:system).with("ssh -p 234 mrderpyman2014@789.789.789.789 \"cd /srv/www\"")
        subject.execute({ :"ssh-opts" => '-p 234', :"ssh-cmd" => 'cd /srv/www'})
      end

      it "executes ssh through an instance with a public_ip to get to one with a private_ip" do
        allow(subject).to receive(:instances) {[
                            { hostname: "host1", elastic_ip: "123.123.123.123" },
                            { hostname: "host2", private_ip: "789.789.789.789" }
                          ]}
        expect(subject).to receive(:system).with("ssh -A -t mrderpyman2014@123.123.123.123 ssh 789.789.789.789")
        subject.execute
      end

      context "when internal_ssh_only is enabled" do
        let(:client) { double(config: double(opsworks_config: {stack_id: "1234", internal_ssh_only: true})) }
        it "ssh to a private_ip " do
          allow(subject).to receive(:instances) {[
                              { hostname: "host1", elastic_ip: "123.123.123.123", private_ip: "10.10.10.10"}
                            ]}
          expect(subject).to receive(:system).with("ssh mrderpyman2014@10.10.10.10")
          expect(Output).to receive(:say).with("This stack requires a private connection, only using internal IPs.")
          subject.execute
        end
      end
    end

    context "#client" do
      it "generates a new aws client from the given configs" do
        expect(Client).to receive(:new).with('derp')
        subject.client
      end
    end

    context "#instances" do
      it "makes a describe_instances API call" do
        expect(client).to receive(:api_call).with(:describe_instances, {stack_id: "1234"})
          .and_return(instances: [{:name => :foo, :status => "online"},{:name => :bar, :status => "stopped"}])
        expect(subject.instances).to eq([{:name => :foo, :status=>"online"}])
      end
      it "sorts instances by hostname" do
        expect(client).to receive(:api_call).with(:describe_instances, {stack_id: "1234"})
          .and_return(instances: [{:hostname => "taco", :status => "online"},{:hostname => "bar", :status => "online"}])
        expect(subject.instances).to eq([{:hostname => "bar", :status=>"online"}, {:hostname => "taco", :status=>"online"}])
      end
    end

    context "#ssh_username" do
      it "makes a describe_my_user_profile API call" do
        allow(user_profile).to receive(:ssh_username).and_return("captkirk01")
        expect(subject.ssh_username).to eq("captkirk01")
      end
    end

    context "#bastion_ip" do
      let(:instance) { { hostname: "host1", elastic_ip: "123.123.123.123", public_ip: "123.345.567.789", private_ip: "10.10.10.10" } }
      context "when bastion_layer_id is enabled" do
        let(:client) { double(config: double(opsworks_config: {stack_id: "1234", bastion_layer_id: "4321"})) }
        it "returns a Bastion IP" do
          expect(client).to receive(:api_call).with(:describe_instances, {layer_id: "4321"})
            .and_return(instances: [{:hostname => "taco", :status => "stopped", :public_ip => "123.123.123.123"},{:hostname => "bar", :status => "online", :public_ip => "213.213.213.213"}])
          expect(Output).to receive(:say).with("Connecting via bastion with IP 213.213.213.213")
          expect(subject.bastion_ip).to eq("213.213.213.213")
        end
      end
      context "when bastion_hostname is enabled" do
        let(:client) { double(config: double(opsworks_config: {stack_id: "1234", bastion_hostname: "sebastion"})) }
        it "returns the hostname of the bastion host" do
          expect(subject.bastion_ip).to eq("sebastion")
        end
      end
      context "when bastion is not used" do
        it "returns false" do
          expect(subject.bastion_ip).to eq(false)
        end
      end
    end

    context "#ssh_ip" do
      let(:instance) { { hostname: "host1", elastic_ip: "123.123.123.123", public_ip: "123.345.567.789", private_ip: "10.10.10.10" } }
      context "when internal_ssh_only is enabled" do
        let(:client) { double(config: double(opsworks_config: {stack_id: "1234", internal_ssh_only: true})) }
        it "returns an internal IP" do
          expect(Output).to receive(:say).with("This stack requires a private connection, only using internal IPs.")
          expect(subject.ssh_ip(instance)).to eq("10.10.10.10")
        end
      end
      context "when internal_ssh_only is not enabled" do
        it "returns elastic IP if it is present" do
          expect(subject.ssh_ip(instance)).to eq("123.123.123.123")
        end
        it "returns a public IP if there is no elastic ip" do
          instance.delete(:elastic_ip)
          expect(subject.ssh_ip(instance)).to eq("123.345.567.789")
        end
      end
    end

    context "#public_ips" do
      it "selects all EIPs and then public_ip on the stack" do
        allow(subject).to receive(:instances) {[
                    { hostname: "host1", elastic_ip: "123.123.123.123", public_ip: "123.345.567.789"},
                    { hostname: "host2", public_ip: "456.456.456.456" },
                    { hostname: "host2", private_ip: "789.789.789.789" },
                  ]}
        expect(subject.public_ips).to eq(["123.123.123.123","456.456.456.456"])
      end
    end

    context "#ssh_command" do
      before do
        allow(subject).to receive(:ssh_username) {"mrderpyman2014"}
        allow(subject).to receive(:instances) {[
                    { hostname: "host1", elastic_ip: "123.123.123.123" },
                    { hostname: "host2", private_ip: "789.789.789.789" }
                  ]}
      end
      it "creates the proper ssh_command for an instance with a public/elastic ip" do
        expect(subject.ssh_command({elastic_ip: "123.123.123.123" })).to eq("ssh mrderpyman2014@123.123.123.123")
      end
      it "creates the proper ssh_command for an instance with a private ip" do
        expect(subject.ssh_command({private_ip: "789.789.789.789" })).to eq("ssh -A -t mrderpyman2014@123.123.123.123 ssh 789.789.789.789")
      end
      it "properly adds ssh options to the ssh_command for an instance with a public ip" do
        expect(subject.ssh_command({elastic_ip: "123.123.123.123" }, { :"ssh-opts" => "-c"})).to eq("ssh -c mrderpyman2014@123.123.123.123")
      end
      it "properly adds ssh options to the ssh_command for an instance with a private ip" do
        expect(subject.ssh_command({private_ip: "789.789.789.789"}, { :"ssh-opts" => "-c"} )).to eq("ssh -c -A -t mrderpyman2014@123.123.123.123 ssh 789.789.789.789")
      end
      context "when bastion_layer_id is enabled" do
        let(:client) { double(config: double(opsworks_config: {stack_id: "1234", bastion_layer_id: "4321"})) }
        it "creates the proper ssh_command for an instance with a private ip" do
          expect(client).to receive(:api_call).with(:describe_instances, {layer_id: "4321"})
            .and_return(instances: [
                        {:hostname => "taco", :status => "stopped", :public_ip => "123.123.123.123"},
                        {:hostname => "bar", :status => "online", :public_ip => "213.213.213.213"}
            ])
          expect(subject.ssh_command({private_ip: "789.789.789.789" })).to eq("ssh -A -t mrderpyman2014@213.213.213.213 ssh 789.789.789.789")
        end
        it "properly adds ssh options to the ssh_command for an instance with a private ip" do
          expect(client).to receive(:api_call).with(:describe_instances, {layer_id: "4321"})
            .and_return(instances: [
                        {:hostname => "taco", :status => "stopped", :public_ip => "123.123.123.123"},
                        {:hostname => "bar", :status => "online", :public_ip => "213.213.213.213"}
            ])
          expect(subject.ssh_command({private_ip: "789.789.789.789"}, { :"ssh-opts" => "-c"} )).to eq("ssh -c -A -t mrderpyman2014@213.213.213.213 ssh 789.789.789.789")
        end
      end
      context "when bastion_hostname is enabled" do
        let(:client) { double(config: double(opsworks_config: {stack_id: "1234", bastion_hostname: "sebastion"})) }
        it "creates the proper ssh_command for an instance with a private ip" do
          expect(Output).to receive(:say).with("Connecting via bastion with hostname 'sebastion'")
          expect(subject.ssh_command({private_ip: "789.789.789.789" })).to eq("ssh -A -t mrderpyman2014@sebastion ssh 789.789.789.789")
        end
        it "properly adds ssh options to the ssh_command for an instance with a private ip" do
          expect(Output).to receive(:say).with("Connecting via bastion with hostname 'sebastion'")
          expect(subject.ssh_command({private_ip: "789.789.789.789"}, { :"ssh-opts" => "-c"} )).to eq("ssh -c -A -t mrderpyman2014@sebastion ssh 789.789.789.789")
        end
      end
    end

    context "#instance_info" do
      before do
        allow(stack).to receive(:layer_name).with("1").and_return("one")
        allow(stack).to receive(:layer_name).with("2").and_return("two")
        allow(subject).to receive(:instances) {[
                    { hostname: "host1", public_ip: "123.123.123.123", layer_ids: [1] },
                    { hostname: "host2", private_ip: "789.789.789.789", layer_ids: [1,2] },
                    { hostname: "host3", private_ip: "789.789.789.789", layer_ids: nil }
                  ]}
        it "should handle no layers or EIP" do
          expect(subject.instance_info({})).to eq("()")
        end
        it "should list a layer" do
          expect(subject.instance_info(layer_ids: [1])).to eq("(one)")
        end
        it "should list layers" do
          expect(subject.instance_info(layer_ids: [1, 2])).to eq("(one, two)")
        end
        it "should list a EIP" do
          expect(subject.instance_info(elastic_ip: "1.1.1.1")).to eq("(EIP)")
        end
        it "should list all info" do
          expect(subject.instance_info(layer_ids: [1], elastic_ip: "1.1.1.1")).to eq("(one, EIP)")
        end
      end
    end
  end
end
