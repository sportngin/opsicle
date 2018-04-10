require "spec_helper"
require "opsicle"
require 'gli'
require "opsicle/user_profile"

module Opsicle
  describe ManageableStack do
    before do
      @stack = double('stack', :vpc_id => 'vpc-123456')
      @opsworks_adapter = double('opsworks_adapter', :stack => @stack)
    end

    context "#get_stack" do
      it "should gather opsworks instances for that layer" do
        stack = ManageableStack.new(12345, @opsworks_adapter)
        expect(@opsworks_adapter).to receive(:stack).and_return(@stack)
        stack.get_stack
      end
    end
  end
end
