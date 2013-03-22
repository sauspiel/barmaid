# Barmaid

Provides a restful HTTP api for PostgreSQL backup tool [barman](http://pgbarman.org) to recover backups to several targets (paths or hosts).

## Requirements

It uses [redis](http://redis.io) for its job queues, so you need a minimal redis server somewhere before you start.

## Installation

Add this line to your application's Gemfile:

    gem 'barmaid'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install barmaid

## Config

Copy config/barmaid.yml.sample to config/barmaid.yml and change it to your needs.

<pre>
"jobs": '/var/lib/barman/barmaid/jobs'              
"servers":                             
  "testdb1":                                        
    "targets":
      "localhost":                                    
        "path": '/var/lib/barman/recover/testbd1'    
      "staging":
        "path": '/var/lib/postgresql/9.2/main'
        "remote_ssh_cmd": 'ssh postgres@10.20.20.4'   
  "testdb2":                                        
    "targets": 
      "localhost":
        "path": '/var/lib/barman/recover/backup2'
      "host3":
        "path": '/var/lib/postgresql/9.1/main'
        "remote_ssh_cmd": 'ssh postgres@10.20.20.10'
        "recover_job": 'RecoverJobHost3'
</pre>

"jobs": (optional) the path to your custom recover jobs. all *.rb files in this path will be loaded on startup</br>
"servers": (required) a list of servers in barman terms (should be equivalent to `barman list-server`)</br>
"target": (required) a descriptive name for a target (or destination), has to be unique to a server (e.g. 'localhost')</br>
"path": (required) filesystem path where the recover backup should be placed. when 'remote_ssh_cmd' is given, path is meant to be on the remote host, otherwise local</br>
"remote_ssh_cmd": (optional) the recover will be done over ssh (same as 'barman recover --remote-ssh-command')</br>
"recover_job_name": (optinal) a custom recover job script can be used for a target, for example to prepare several things before or after the recover. when not set, the default recover job will be triggered, which does just a 'barman recover'</br>

## API

### GET /api/servers

Retrieve a list of all servers

Example:

    curl http://localhost:9292/api/servers

```json
[
  "testdb1",
  "testdb2"
]
```

### GET /api/servers/id/targets

Retrieve all targets for a specific server

Example:

    curl -H http://localhost:9292/api/servers/testdb1/targets

```json
[
  "localhost",
  "127.0.0.1"
]
```

### GET /api/servers/id/targets/id

Retrieve details for a specific target

Example:

    curl http://localhost:9292/api/servers/testdb1/targets/127.0.0.1

```json
{
  "path": "/var/lib/barman/recover/127.0.0.1",
  "remote_ssh_cmd": "ssh barman@127.0.0.1"
  "ts_backup_label_old": "2013-03-22 07:25:14 +0100" # not yet implemented
}
```

"ts_backup_label_old" shows (afaik) the timestamp of the last database backup on the target (not yet implemented)

### GET /api/servers/id/backups

Retrieve a list of backups for a server

Example
  
    curl http://localhost:9292/api/servers/testdb1/backups

```json
[
  "20130318T080002",
  "20130225T192654"
]
```

### GET /api/servers/id/backups/id

Retrieve details about a backup

Example

    curl http://localhost:9292/api/servers/testdb1/backups/20130322T072507

```json
{
  "size": 19355207,
  "status": "done",
  "backup_start": "2013-03-22 07:25:07 +0100",
  "backup_end": "2013-03-22 07:25:14 +0100",
  "timeline": 1,
  "wal_file_size": 973078528
}%
```

### POST /api/recover_jobs

Creates a new recover job and recovers the backup to a target

Example

    curl -v -X POST -d '{"server":"testdb1", "target":"127.0.0.1", "backup_id": "20130322T072507"}' http://localhost:9292/api/recover_jobs


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Meta

Written by [Holger Amann](holger@sauspiel.de), sponsored by [Sauspiel GmbH](https://www.sauspiel.de)

Released under the [MIT License](http://opensource.org/licenses/mit-license.php)
