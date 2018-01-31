require 'hashdiff'
require 'opsicle/output'

module Opsicle
  class Update
    attr_reader :client, :type

    def initialize(environment, type)
      @client = Client.new(environment)
      @type = type
    end

    def execute(values, options)
      before = describe
      update(values)
      after = describe
      print(before, after)
    end

    def describe
      api_method = "describe_#{@type}s"
      api_opts = {
          :"#{@type}_ids" => [client.config.opsworks_config[:"#{@type}_id"]]
      }
      client.api_call(api_method, api_opts)[:"#{@type}s"][0]
    end

    def update(values)
      api_method = "update_#{@type}"
      api_opts = values.merge(:"#{@type}_id" => client.config.opsworks_config[:"#{@type}_id"])
      client.api_call(api_method, api_opts)
    end

    def print(before, after)
      diff = HashDiff.diff(before, after)
      Output.say("Changes: #{diff.size}")
      Output.terminal.say(Terminal::Table.new headings: %w[Change Key Before After], rows: format_diff(diff)) if diff.size > 0
    end

    def format_diff(diff)
      diff.map { |change|
        case change[0]
          when '-'
            change.insert(3, nil)
            change.map! { |i| Output.format(i, :removal) }
          when '+'
            change.insert(2, nil)
            change.map! { |i| Output.format(i, :addition) }
          when '~'
            change.map! { |i| Output.format(i, :modification) }
        end
        change
      }
    end

  end
end
