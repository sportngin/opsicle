#### v2.4.0
#### v2.4.0
* Generate valid hostnames when source hostname doesn't end with digits

  > mykola42: : https://github.com/sportngin/opsicle/pull/118

* make aws profile optional (support cross account assume role)

  > troyready: : https://github.com/sportngin/opsicle/pull/119
 
* require minitar ~> 0.6

  > troyready: : https://github.com/sportngin/opsicle/pull/120
  
#### v2.3.1
* Ruby Compatibility

  > Brian Bergstrom: : https://github.com/sportngin/opsicle/pull/116

#### v2.3.0
* Add ability to override AMI id, agent version, and instance type when cloning an instance

  > Emma Sax: Unknown User: https://github.com/sportngin/opsicle/pull/112

#### v2.2.1
* Regional Endpoints

  > Mykola: Unknown User, Andy Fleener: https://github.com/sportngin/opsicle/pull/111

#### v2.2.0
* Support for configurable aws credentials profile name

  > Brian Bergstrom: : https://github.com/sportngin/opsicle/pull/108

#### v2.1.0
* Clone instances

  > Mykola, Emma Sax: Brian Bergstrom, Andy Fleener: https://github.com/sportngin/opsicle/pull/95

#### v2.0.2
* Make new directory for credentials file if it doesn't already exist

  > Emma Sax: Andy Fleener: https://github.com/sportngin/opsicle/pull/104

#### v2.0.1
* Only prompt for MFA if requested by the user

  > Matt Krieger: Brian Bergstrom: https://github.com/sportngin/opsicle/pull/105

#### v2.0.0
* Adding configuration for authenticating to AWS through credentials file

  > Emma Sax: Brian Bergstrom: https://github.com/sportngin/opsicle/pull/100

#### v1.1.1
* Fix bug with failure-log command

  > Emma Sax: Brian Bergstrom: https://github.com/sportngin/opsicle/pull/99

#### v1.1.0
* Adding command to get recent failure log from failed deployment

  > Emma Sax: Chris Arcand, Brian Bergstrom: https://github.com/sportngin/opsicle/pull/97

#### v1.0.1
* Fix bug that prevents users from updating chef cookbooks on aws-sdk v2

  > Emma Sax: Brian Bergstrom: https://github.com/sportngin/opsicle/pull/98

#### v1.0.0
* Simplifying legacy-credential-converter to use hash to read credentials, not regexes"

  > Brian Bergstrom, newzac, Emma Sax: : https://github.com/sportngin/opsicle/pull/92

* Upgrading aws-sdk to v2 from v1

  > Emma Sax: Andy Fleener: https://github.com/sportngin/opsicle/pull/91

* Making conversion command from .fog to .aws/credentials

  > Emma Sax: Andy Fleener: https://github.com/sportngin/opsicle/pull/90

#### v0.18.1
#### v0.18.0
#### v0.16.0
#### v0.15.0
#### v0.14.0
#### v0.13.1
* No TTY compatibility for monitor

  > Brian Bergstrom, Chris Arcand: Nick LaMuro: https://github.com/sportngin/opsicle/pull/78

#### v0.13.0
* Adding update command

  > Brian Bergstrom: https://github.com/sportngin/opsicle/pull/76
  
#### v0.12.0
* Adding additional info to list instances, ssh and monitor.

  > Brian Bergstrom: https://github.com/sportngin/opsicle/pull/75
  
#### v0.11.0
* Adding MFA support.

  > Brian Bergstrom: https://github.com/sportngin/opsicle/pull/74
  
#### v0.10.0
* Adding the ability connect to a private instance with a proxy

  > Elliot Hursh: https://github.com/sportngin/opsicle/pull/73
  
#### v0.9.0
