require "spec_helper"
require "opsicle"


module Opsicle
  describe Permit do
    let(:client) { double(config: double(opsworks_config: { stack_id: '1234' })) }
    subject { Permit.new('derp')}
    let(:describe_user_profiles) {
      { user_profiles: [
          {name: "herp.derp", ssh_username: "herpderp", iam_user_arn: '8675309'},
          {name: "doop.derp", ssh_username: "doopderp", iam_user_arn: '8675342'},
          {name: "billy.mays", ssh_username: "billymays", iam_user_arn: '8675338'},
          {name: "brent.favor", ssh_username: "brentfavor", iam_user_arn: '4'}
        ]
      }
    }

    before do
      allow_any_instance_of(UserProfile).to receive(:arn).and_return('8675309')
      allow(client).to receive(:api_call).with(:describe_stacks).and_return({ stacks: [{ stack_id: '1234' }, { stack_id: '5678' }] })
      allow(client).to receive(:api_call).with(:describe_user_profiles).and_return(describe_user_profiles)
      allow(Client).to receive(:new).with("derp").and_return(client)
    end

    context '#execute' do
      it 'calls set_permission for current_user on current stack by default' do
        expect(client).to receive(:api_call).with(:set_permission, { allow_ssh: true, allow_sudo: true, iam_user_arn: '8675309' , stack_id: '1234' })
        subject.execute({})
      end

      it 'calls set_permission for current user for all stacks with all_stacks option' do
        expect(client).to receive(:api_call).with(:set_permission, { allow_ssh: true, allow_sudo: true, iam_user_arn: '8675309' , stack_id: '1234' })
        expect(client).to receive(:api_call).with(:set_permission, { allow_ssh: true, allow_sudo: true, iam_user_arn: '8675309' , stack_id: '5678' })
        subject.execute({all_stacks: true})
      end

      it 'calls set_permission for selected users for current stack' do
        expect(client).to receive(:api_call).with(:set_permission, { allow_ssh: true, allow_sudo: true, iam_user_arn: '8675342' , stack_id: '1234' })
        expect(client).to receive(:api_call).with(:set_permission, { allow_ssh: true, allow_sudo: true, iam_user_arn: '4' , stack_id: '1234' })
        subject.execute(user: ['doop.derp', 'brentfavor'])
      end

      it 'calls set_permission for selected users for all stacks' do
        expect(client).to receive(:api_call).with(:set_permission, { allow_ssh: true, allow_sudo: true, iam_user_arn: '8675309' , stack_id: '1234' })
        expect(client).to receive(:api_call).with(:set_permission, { allow_ssh: true, allow_sudo: true, iam_user_arn: '8675338' , stack_id: '1234' })
        expect(client).to receive(:api_call).with(:set_permission, { allow_ssh: true, allow_sudo: true, iam_user_arn: '8675309' , stack_id: '5678' })
        expect(client).to receive(:api_call).with(:set_permission, { allow_ssh: true, allow_sudo: true, iam_user_arn: '8675338' , stack_id: '5678' })
        subject.execute(user: ['herp.derp', 'billy.mays'], all_stacks: true)
      end
    end

    context '#iam_user_arns' do
      it 'finds a user arn by name' do
        expect(subject.iam_user_arns(['billy.mays', 'doop.derp'])).to eq(['8675338', '8675342'])
      end

      it 'finds a user arn by ssh_username' do
        expect(subject.iam_user_arns(['brentfavor', 'herp.derp'])).to eq(['4', '8675309'])
      end

      it 'finds by a mix of name and ssh_username' do
        expect(subject.iam_user_arns(['brentfavor', 'doop.derp'])).to eq(['4', '8675342'])
      end

      it 'should thow exception if user is not found' do
        expect{subject.iam_user_arns(['bobby.jones'])}.to raise_error(ArgumentError, /bobby.jones/)
      end
    end

    context '#all_stack_ids' do
      it 'maps stack ids from describe_stacks' do
        expect(subject.all_stack_ids).to eq(['1234','5678'])
      end
    end
  end
end
