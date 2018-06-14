module Opsicle
  class Permit
    def initialize(environment)
      @client = Client.new(environment)
    end

    def execute(options={})
      stack_ids = options[:all_stacks] ? all_stack_ids : [current_stack_id]
      stack_ids.each do |stack_id|
        iam_user_arns(options[:user]).each do |arn|
          @client.api_call(:set_permission, { allow_ssh: true, allow_sudo: true, iam_user_arn: arn , stack_id: stack_id } )
        end
      end
    end

    def all_stack_ids
      @client.api_call(:describe_stacks)[:stacks].map{ |stack| stack[:stack_id] }
    end

    def current_stack_id
      @client.config.opsworks_config[:stack_id]
    end

    def iam_user_arns(user_names)
      if user_names && !user_names.empty?
        profiles = @client.api_call(:describe_user_profiles)[:user_profiles]
        user_names.map do |user_name|
          profile = profiles.detect{ |profile| profile[:name] == user_name || profile[:ssh_username] == user_name}
          raise ArgumentError, "User #{user_name} not found" unless profile
          profile[:iam_user_arn]
        end
      else
        [UserProfile.new(@client).arn]
      end
    end
  end
end
