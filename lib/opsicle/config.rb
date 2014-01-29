require 'yaml'
require 'rugged'

module Opsicle
  class Config
    attr_reader :environment

    def initialize(environment)
      @environment = environment.to_sym
    end

    def aws_config
      return @aws_config if @aws_config
      fog_confg = load_config(File.expand_path('~/.fog'))
      @aws_config = { access_key_id: fog_confg[:aws_access_key_id], secret_access_key: fog_confg[:aws_secret_access_key] }
    end

    def local_or_git_root(file)
      # Check in current dir
      if File.exist?(file)
        return file
      else
        # Check in repo root
        $stderr.puts "#{file} not found, checking in git repo root"
        begin
          path = Rugged::Repository.discover('.')
          repo = Rugged::Repository.new(path)
          return File.join(repo.workdir, file)
        rescue => error
          fail "#{file} not found (Error checking git repo: #{error.message})"
        end
      end
    end

    def opsworks_config
      @opsworks_config ||= load_config(local_or_git_root('.opsicle'))
    end

    def configure_aws!
      AWS.config(aws_config)
    end

    def load_config(file)
      symbolize_keys(YAML.load_file(file))[environment] rescue {}
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
  end
end
