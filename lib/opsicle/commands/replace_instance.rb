module Opsicle
  class ReplaceInstance
    def initialize(environment)
      @clone_instance = CloneInstance.new(environment)
    end

    def execute(options={})
      @clone_instance.execute(options.merge(replace: true))
    end
  end
end
