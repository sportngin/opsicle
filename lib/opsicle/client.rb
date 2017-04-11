require 'opsicle/config'

module Opsicle
  class Client
    attr_reader :opsworks
    attr_reader :s3
    attr_reader :config

    def initialize(environment)
      @config = Config.instance
      @config.configure_aws_environment!(environment)
      credentials = @config.aws_credentials
      region = @config.opsworks_region
      aws_opts = {region: region}
      aws_opts[:credentials] = credentials unless credentials.nil?
      @opsworks = Aws::OpsWorks::Client.new aws_opts
      @s3 = Aws::S3::Client.new aws_opts
    end

    def run_command(command, command_args={}, options={})
      opts = command_options(command, command_args, options)
      Output.say_verbose "OpsWorks call: create_deployment(#{opts})"
      opsworks.create_deployment(opts)
    end

    def api_call(command, options={})
      opsworks.public_send(command, options).to_h
    end

    def opsworks_url
      "https://console.aws.amazon.com/opsworks/home?#/stack/#{@config.opsworks_config[:stack_id]}"
    end

    def stack_config
      {
        stack_id: config.opsworks_config[:stack_id],
        app_id: config.opsworks_config[:app_id]
      }
    end

    def command_options(command, command_args={}, options={})
      stack_config.merge(options).merge({ command: { name: command, args: command_args } })
    end
    private :command_options

  end
end
