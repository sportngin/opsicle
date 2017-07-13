require "spec_helper"
require "opsicle"
require 'gli'
require "opsicle/user_profile"

module Opsicle
  describe CloneableStack do
    before do
    @stack = double('stack', :vpc_id => 'vpc-123456')
      @stacks = double('stacks', :stacks => [@stack])
      @opsworks = double('opsworks', :describe_stacks => @stacks)
    end

    context "#get_stack" do
      it "should gather opsworks instances for that layer" do
        stack = CloneableStack.new(12345, @opsworks)
        expect(@opsworks).to receive(:describe_stacks).and_return(@stacks)
        expect(@stacks).to receive(:stacks)
        stack.get_stack
      end
    end
  end
end
