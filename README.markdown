#Opsicle, an OpsWorks CLI
A gem bringing the glory of OpsWorks to your command line.

[![Gem Version](https://badge.fury.io/rb/opsicle.png)](http://badge.fury.io/rb/opsicle)
[![Build Status](https://travis-ci.org/sportngin/opsicle.png?branch=master)](https://travis-ci.org/sportngin/opsicle)

## Installation
Add this line to your project's Gemfile:

```ruby
gem 'opsicle'
```

### Set up an Application to use opsicle

```yaml
# your_app_root/.opsicle

staging:
  stack_id: opsworks-stack-id
  app_id: opsworks-app-id
production:
  stack_id: opsworks-stack-id
  app_id: opsworks-app-id
production2:
  stack_id: opsworks-stack-id
  app_id: opsworks-app-id
  profile_name: production
  region: us-west-2
```

Opsicle v2+ uses AWS SDK shared credentials.  See: https://aws.amazon.com/blogs/security/a-new-and-standardized-way-to-manage-credentials-in-the-aws-sdks/
```ini
# ~/.aws/credentials

[staging]
aws_access_key_id = YOUR_AWS_ACCESS_KEY
aws_secret_access_key = YOUR_AWS_SECRET_ACCESS_KEY
[production]
aws_access_key_id: YOUR_AWS_ACCESS_KEY
aws_secret_access_key = YOUR_AWS_SECRET_ACCESS_KEY
```

## Using Opsicle

Run `opsicle help` for a full list of commands and their uses.

Opsicle accepts a `--verbose` flag or the VERBOSE environment variable to show additional information as commands are run.
Opsicle accepts a DEBUG environment variable to show additional logging such as stack traces for failed commands.

Some common commands:

### Deployments
```bash

# Run a basic deploy for the current app
opsicle deploy staging

# Run the deploy for production
opsicle deploy production

```
By default, deploying opens the Opsicle Stack Monitor.
You may also use `--browser` to open the OpsWorks deployments screen instead,
or `--no-monitor` to ignore both monitoring options

### Failure-log
```bash

# Get the failure log from a deployment for the current app
opsicle failure-log staging
```

This will open a browser window the failure log from the most recent failure log from
a deployment in the current app.

### SSH
```bash
# SSH to a server instance in the given environment stack
opsicle ssh staging

# Set your user SSH key (PUBLIC KEY) for OpsWorks
opsicle ssh-key staging <key-file>

```

### Stack Monitor
```bash
# Launch the Opsicle Stack Monitor for the given environment stack
opsicle monitor staging

```
### Updating Custom Chef Recipes
```bash
 # Upload a cookbooks directory to S3 and update the stack's custom cookbooks
 opsicle chef-update staging --bucket-name my-opsworks-cookbooks

```
This command accepts a --path argument to the directory of cookbooks to upload. It defaults to 'cookbooks'.
It also accepts a --bucket-name for the base s3 bucket. This flag is required.

### Update
Update an OpsWorks resource like a stack, layer or app with a given set of property values.
The values can be passed as inline JSON or as a path to a YAML file.
Naming and value format needs to follow what is defined for the [AWS Ruby SDK](http://docs.aws.amazon.com/AWSRubySDK/latest/AWS/OpsWorks/Client.html).
Upon successful execution a table of the resulting changes is printed to stdout.

For example:
```
opsicle --debug update staging stack -j '{"use_opsworks_security_groups":false, "custom_json":"{\"foo\":5}"}'
opsicle --debug update staging app -y app.yml
```

### Using a Docker Container
Since local dev environments change so frequently, this is an option to run opsicle commands inside of an isolated Docker container. This
will help mitigate issues on your local environment as it should be the same environment in the docker container every time. There is minimal
setup to get this method to work.

Create the Docker image:
```
docker build . -t dev/opsicle:latest
```

Create an alias in your .bashrc file:
```
alias opsicle='docker run -it -v $(pwd)/.opsicle:/.opsicle -v ~/.aws/credentials:/root/.aws/credentials -v ~/.ssh:/root/.ssh dev/opsicle:latest'
```

This will mount the .opsicle config file for the directory you are currently in. It will also mount your AWS credentials file and your .ssh directory when starting the container.
You can then run opsicle commands as if you were using the executable, but it will be running in a clean, isolated container.
