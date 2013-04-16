## [README](README.md)

## barmaid HTTP API

### GET /api/servers

Retrieve a list of all servers

Example:

    curl http://localhost:9292/api/servers


(shortened)

```json
[
  {"id":"testdb1", "pg_conn_ok":true, "active":true, "targets":["..."], "backups":["..."]},
  {"id":"testdb2", "pg_conn_ok":true, "active":true, "targets":["..."], "backups":["..."]}
]
```

### GET /api/servers/id

Retrieve a specific server

Example:

  curl http://localhost:9292/api/server/testdb1


(shortened)

```json
{
  "active": true,
  "backup_dir": "\/var\/lib\/barman\/testdb1",
  "base_backups_dir": "\/var\/lib\/barman\/testdb1\/base",
  "conn_info": "host=10.20.20.4 user=postgres port=5432",
  "name": "testdb1",
  "pg_conn_ok": true,
  "ssh_check_ok": true,
  "ssh_cmd": "ssh postgres@10.20.20.4",
  "wals_dir": "\/var\/lib\/barman\/testdb1\/wals",
  "id": "testdb1",
  "backups": ["..."],
  "targets": ["..."]
}
```

### GET /api/servers/id/targets

Retrieve all targets for a specific server

Example:

    curl -H http://localhost:9292/api/servers/testdb1/targets


(shortened)

```json
[
  {"id":"localhost", "server_id": "testdb1", "path":"/var/lib/barmand/recover"},
  {"id":"host2", "server_id": "testdb1", "path":"/var/lib/postgresql/9.2/main"}
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


(shortened)

```json
[
  {"id":"20130318T080002", "server_id": "testdb1", "status":"done"},
  {"id":"20130225T192654", "server_id": "testdb1", "status":"failed"}
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
  "status": "queued",
  "time": "2013-04-16 12:57:08 +0200",
  "message": "",
  "pct_complete": 0,
  "server": "testdb1",
  "target": "localhost",
  "backup_id": "20130322T072507",
  "completed_at": "",
  "id": "65d15077f2d0d1256ce25aabcf113aef"
}
```

### GET /api/recover_jobs

Lists all current recover jobs

Example

  curl http://localhost:9292/api/recover_jobs


(shortened)

```json
[
 {"id":"032d06777b177ffd333631b2ce2c2c8e", "status":"completed"},
 {"id":"e25b5485d98a94768e6598d290702a17", "status":"failed"},
]
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
