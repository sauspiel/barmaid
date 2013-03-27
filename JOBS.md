## Recover Jobs

Instead of just recovering a backup to a target (default), you can write your own scripts and assign them to individual targets which then will be called when the worker processes a job.

```ruby
class MyCustomRecoverJob < Barmaid::Job::RecoverJob

  # the constructor is necessary
  def initialize(uuid = nil, options = {})
    super(uuid, options)
    @log.info('Hello from MyCustomRecoverJob')
  end

  def before_recover
    @log.info("before recover")
  end

  def recover
    super # for debugging your script comment this and no recover will be executed
  end

  def after_recover
    @log.info("after recover")
  end

end
```

Put this in a file "my_custom_recover_job.rb", drop that file in the jobs directory and assign it to a target, e.g.

<pre>
:jobs: '/var/lib/barman/barmaid/jobs'
:servers:
  :backup1:
    :targets:
      :localhost:
        :path: '/var/lib/barman/recover/backup1',
        :recover_job_name: 'MyCustomRecoverJob'
</pre>

Note: :recover_job_name: has to be the name of the class.

Start barmaid!

  barman@localhost $ ./bin/rackup

Start a worker!

  barman@localhost $ ./bin/rake resque:work

Create a new recover job by the api!

  barman@localhost $ curl -v -X POST -d '{"server":"backup1","target":"localhost","backup_id":"20130327T154109"}' http://localhost:9292/api/recover_jobs

```json
{"job_id":"3575aa60ddd35cc1dffcd6454aa20657"}
```


After a few seconds the worker should log to stdout:

<pre>
INFO RecoverJob: Trying to instantiate MyCustomRecoverJob
INFO RecoverJob: Hello from MyCustomRecoverJob
INFO RecoverJob: Recovering backup 20130327T154109 for backup1 (options: {"time":1364402347,"status":"queued","server":"backup1","target":"localhost","backup_id":"20130327T154109","recover_opts":{}}}
INFO RecoverJob: before recover
INFO RecoverJob: 5% of Backup 20130327T154109 (backup1) recovered
INFO RecoverJob: 48% of Backup 20130327T154109 (backup1) recovered
INFO RecoverJob: 92% of Backup 20130327T154109 (backup1) recovered
INFO RecoverJob: 100% of Backup 20130327T154109 (backup1) recovered
INFO RecoverJob: after recover
INFO RecoverJob: Recover of backup 20130327T154109 for backup1 (uuid 3575aa60ddd35cc1dffcd6454aa20657) finished
</pre>

\o/


Several attributes are accessable in the scripts like

* @backup : the backup which should be recovered
* @recover_opts : the options like remote ssh command or timestamp
* @log : a logger (.info,.error,.warn,.debug)
* @path : the path (from configuration)
* @uuid : the job's uuid
* @options : everything you've passed to the post params as hash

Please look at the documentation of 'RecoverJob' if you want to get more details!


A real example:

```ruby
```




