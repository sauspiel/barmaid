## [README](README.md)

## barmaid HTTP API

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
}
```

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
}
```

### POST /api/recover_jobs

Creates a new recover job and recovers the backup to a target

Example

    curl -v -X POST -d '{"server":"testdb1", "target":"localhost", "backup_id": "20130322T072507"}' \
    http://localhost:9292/api/recover_jobs
    
```json
{
  "job_id": "032d06777b177ffd333631b2ce2c2c8e"
}
```
