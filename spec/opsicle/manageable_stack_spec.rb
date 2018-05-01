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
  end
end
