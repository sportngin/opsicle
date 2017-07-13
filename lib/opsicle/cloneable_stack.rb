module Opsicle
  class CloneableStack
    attr_accessor :id, :opsworks, :stack, :vpc_id

    def initialize(stack_id, opsworks)
      self.id = stack_id
      self.opsworks = opsworks
      self.stack = get_stack
      self.vpc_id = self.stack.vpc_id
    end

    def get_stack
      @opsworks.describe_stacks({ :stack_ids => [self.id.to_s] }).stacks.first
    end
  end
end
