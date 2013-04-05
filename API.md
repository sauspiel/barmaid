## [README](README.md)

## barmaid HTTP API

### GET /api/servers

Retrieve a list of all servers

Example:

    curl http://localhost:9292/api/servers

```json
[
  {"id":"testdb1"},
  {"id":"testdb2"}
]
```

### GET /api/servers/id/targets

Retrieve all targets for a specific server

Example:

    curl -H http://localhost:9292/api/servers/testdb1/targets

```json
[
  {"id":"localhost", "server_id": "testdb1"},
  {"id":"host2", "server_id": "testdb1"}
]
```

### GET /api/servers/id/targets/id

Retrieve details for a specific target

Example:

    curl http://localhost:9292/api/servers/testdb1/targets/host2

```json
{
  "id":"host2",
  "path": "/var/lib/postgresql/9.2/main",
  "remote_ssh_cmd": "ssh postgres@host2.sample.com",
  "recover_job_name": "RecoverJobHost2",
  "server_id": "testdb1"
}
```

### GET /api/servers/id/backups

Retrieve a list of backups for a server

Example
  
    curl http://localhost:9292/api/servers/testdb1/backups

```json
[
  {"id":"20130318T080002", "server_id": "testdb1"},
  {"id":"20130225T192654", "server_id": "testdb1"}
]
```

### GET /api/servers/id/backups/id

Retrieve details about a backup

Example

    curl http://localhost:9292/api/servers/testdb1/backups/20130322T072507

```json
{
  "id":"20130322T072507",
  "size":19355207,
  "status":"done",
  "backup_start":"2013-03-22 07:25:07 +0100",
  "backup_end":"2013-03-22 07:25:14 +0100",
  "timeline":1,
  "wal_file_size":973078528,
  "server_id": "testdb1"
}
```

### POST /api/recover_jobs

Creates a new recover job and recovers the backup to a target

Example

    curl -v -X POST -d 'server=testdb1&target=localhost&backup_id=20130322T072507' \
    http://localhost:9292/api/recover_jobs
    
```json
{
  "id": "032d06777b177ffd333631b2ce2c2c8e"
}
```

### GET /api/recover_jobs

Lists all current recover jobs

Example

  curl http://localhost:9292/api/recover_jobs

```json
[{"id":"032d06777b177ffd333631b2ce2c2c8e"}]
```

### GET /api/recover_jobs/id

Retrieve details about a recover job

Example

  curl http://localhost:9292/api/recover_jobs/032d06777b177ffd333631b2ce2c2c8e

```json
{
  "id":"032d06777b177ffd333631b2ce2c2c8e",
  "time":1364395857,
  "status":"working",
  "message":"",
  "pct_complete":48,
  "server": "testdb1",
  "target": "localhost",
  "backup_id": "20130322T072507"
  "completed_at": ""
}
```

### DELETE /api/recover_jobs/id

Deletes a recover job from the queue or kills it 

Example

  curl -X DELETE http://localhost:9292/api/recover_jobs/032d06777b177ffd333631b2ce2c2c8e
