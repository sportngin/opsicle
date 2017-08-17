require "opsicle/deploy_helper"

module Opsicle
  class ExecuteCommand
    attr_reader :client

    def initialize(environment, command)
      @environment = environment
      @command = command
      @client = Client.new(environment)
    end

    def execute(options={})
      Output.say "Executing command '#{@command}' on all instances."
      Opsicle::SSH.new(@environment).execute(all: true, :'ssh-cmd' => @command)
    end
  end
end
