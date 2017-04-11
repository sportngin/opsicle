require 'yaml'
require 'aws-sdk'

module Opsicle
  class Config
    OPSICLE_CONFIG_PATH = './.opsicle'
    SESSION_DURATION = 3600

    attr_reader :environment

    def self.instance
      @instance ||= new
    end

    def aws_credentials
      authenticate_with_credentials
    end

    def opsworks_config
      @opsworks_config ||= load_config(OPSICLE_CONFIG_PATH)
    end

    def opsworks_region
      opsworks_config[:region] || "us-east-1"
    end

    def configure_aws_environment!(environment)
      @environment = environment.to_sym
    end

    def load_config(file)
      raise MissingConfig, "Missing configuration file: #{file}  Run 'opsicle help'" unless File.exist?(file)
      env_config = symbolize_keys(YAML.load_file(file))[environment] rescue {}
      raise MissingEnvironment, "Configuration for the \'#{environment}\' environment could not be found in #{file}" unless env_config != nil

      env_config
    end

    def get_mfa_token
      return @token if @token
      @token = Output.ask("Enter MFA token: "){ |q|  q.validate = /^\d{6}$/ }
    end

    # We want all ouf our YAML loaded keys to be symbols
    # taken from http://devblog.avdi.org/2009/07/14/recursively-symbolize-keys/
    def symbolize_keys(hash)
      hash.inject({}){|result, (key, value)|
        new_key = case key
                  when String then key.to_sym
                  else key
                  end
        new_value = case value
                    when Hash then symbolize_keys(value)
                    else value
                    end
        result[new_key] = new_value
        result
      }
    end

    def authenticate_with_credentials
      profile_name = opsworks_config[:profile_name] || @environment.to_s
      begin
        credentials = Aws::SharedCredentials.new(profile_name: profile_name)
      rescue Aws::Errors::NoSuchProfileError
        if ENV['AWS_SESSION_TOKEN']
          Output.say('AWS profile not found; falling back to environment credentials', :debug)
        else
          raise Aws::Errors::NoSuchProfileError, "AWS profile #{profile_name} not found"
        end
      end
      region = opsworks_region

      if !credentials.nil? && !credentials.set?
        abort('Opsicle can no longer authenticate through your ~/.fog file. Please run `opsicle legacy-credential-converter` before proceeding.')
      end

      aws_opts = {region: region}
      aws_opts[:credentials] = credentials unless credentials.nil?
      Aws.config.update aws_opts

      iam = Aws::IAM::Client.new

       # this will be an array of 0 or 1 because iam.list_mfa_devices.mfa_devices will only return 0 or 1 device per user;
       # if user doesn't have MFA enabled, then this loop won't even execute
      if $use_mfa
        iam.list_mfa_devices.mfa_devices.each do |mfadevice|
          mfa_serial_number = mfadevice.serial_number
          get_mfa_token
          session_credentials_hash = get_session(mfa_serial_number,
                                                 credentials.credentials.access_key_id,
                                                 credentials.credentials.secret_access_key).credentials

          credentials = Aws::Credentials.new(session_credentials_hash.access_key_id,
                                                     session_credentials_hash.secret_access_key,
                                                     session_credentials_hash.session_token)
        end
      end

      return credentials
    end

    def get_session(mfa_serial_number, access_key_id, secret_access_key)
      return @session if @session
      sts = Aws::STS::Client.new(access_key_id: access_key_id,
                                 secret_access_key: secret_access_key,
                                 region: 'us-east-1')
      @session = sts.get_session_token(duration_seconds: SESSION_DURATION,
                                       serial_number: mfa_serial_number,
                                       token_code: @token)
    end

    MissingConfig = Class.new(StandardError)
    MissingEnvironment = Class.new(StandardError)

  end
end
