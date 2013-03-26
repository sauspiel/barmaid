# barmaid

Provides a restful HTTP api for PostgreSQL backup tool [barman](http://pgbarman.org) to recover backups to several targets (paths or hosts).

## Requirements

[Ruby](http://www.ruby-lang.org/en/downloads), a working [barman](http://pgbarman.org) installation and [redis](http://redis.io) for its job queues, so you need a minimal redis server somewhere before you start. If you don't have one, executing [these](http://redis.io/download) steps should be sufficent.


## Installation

barmaid has to be installed and run as the same user as barman (default 'barman'), otherwise it won't have access to your backups. So consider to do all steps as 'barman' user.

    cd $HOME

### From Source

    $ git clone https://github.com/sauspiel/barmaid.git
    $ cd barmaid && bundle install --path vendor/bundle --binstubs

### Gem

Note: barmaid isn't released as gem yet, so please install from source!

    $ mkdir barmaid && cd barmaid
    
Create a 'Gemfile' with the following content

    gem 'barmaid'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install barmaid

## Config

### resque/redis

    $ cp config/resque.yml.sample config/resque.yml
 
 It should work out of the box if your redis server is running on the same host, otherwise adapt the connection settings.

### barmaid

    $ cp config/barmaid.yml.sample config/barmaid.yml

Adapt barmaid.yml to your needs:

<pre>
:jobs: '/var/lib/barman/barmaid/jobs'
:servers:
  :backup1:
    :targets:
      :localhost:
        :path: '/var/lib/barman/recover/backup1'
      :host2:
        :path: '/var/lib/postgresql/9.2/main'
        :remote_ssh_cmd: 'ssh postgres@host2.sample.com'
        :recover_job_name: 'RecoverJobHost2'
  :backup2:
    :targets:
      :localhost:
        :path: '/var/lib/barman/recover/backup2'
      :host3:
        :path: '/var/lib/postgresql/9.2/main'
        :remote_ssh_cmd: 'ssh postgres@host3.sample.com'
        :recover_job_name: 'RecoverJobHost3'
</pre>

* :jobs: (optional) the path to your custom recover jobs. all *.rb files in this path will be loaded on startup
* :servers: (required) a list of servers in barman terms (should be equivalent to `barman list-server`)
* :targets: (required) a list of targets (think of destinations), each one with a descriptive name (without dots) and unique in context of a server
* :path: (required) filesystem path where the recover backup should be placed. when 'remote_ssh_cmd' is given, path is meant to be on the remote host, otherwise local
* :remote_ssh_cmd: (optional) the recover will be done over ssh (same as 'barman recover --remote-ssh-command')
* :recover_job_name: (optinal) a custom recover job script can be used for a target, for example to prepare several things before or after the recover. when not set, the default recover job will be triggered, which does just a 'barman recover'


## Starting barmaid

If everything is in place, start barmaid with default 0.0.0.0:9292

    $ ./bin/rackup

or to listen on 127.0.0.1:8080

    $ ./bin/rackup -o 127.0.0.1 -p 8080
    
## [HTTP API](API.md)


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Meta

Written by [Holger Amann](holger@sauspiel.de), sponsored by [Sauspiel GmbH](https://www.sauspiel.de)

Released under the [MIT License](http://opensource.org/licenses/mit-license.php)
