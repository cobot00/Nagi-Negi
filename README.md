# Naginegi

Generate Embulk config and BigQuery schema from MySQL and PostgreSQL schema and run Embulk.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'naginegi'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install naginegi

## Embulk setup
`Naginegi` is utility for `Embulk` .
You need to install `Embulk` and install some gems like below.

```bash
embulk gem install embulk-input-mysql --version 0.10.1
embulk gem install embulk-input-postgresql --version 0.10.1
embulk gem install embulk-output-bigquery --version 0.6.4
embulk gem install embulk-parser-jsonl --version 0.2.0
embulk gem install embulk-formatter-jsonl --version 0.1.4
```

## Usage
Require `database.yml` and `table.yml`.  
`database.yml` requires `db_type` (mysql or postgresql).

|RDBMS|db_type|
|---|---|
|MySQL|mysql|
|PostgreSQL|postgresql|

Below is a sample config file.

### database.yml
```yml
db01:
  db_type: mysql
  host: localhost
  username: root
  password: pswd
  database: production
  bq_dataset: mysql

db02:
  db_type: postgresql
  host: localhost
  username: root
  password: pswd
  database: production
  bq_dataset: pg

```

**Caution: Embulk doesn't allow no password for MySQL**

### table.yml
```yml
db01:
  tables:
    - name: users
    - name: events
    - name: hobbies

db02:
  tables:
    - name: administrators
    - name: configs
```

### sample
Naginegi requires BigQuery parameters like below.

#### using json key file path
```ruby
[sample.rb]
require 'naginegi'

config = {
 'project_id' => 'BIGQUERY_PROJECT_ID',
 'service_email' => 'SERVICE_ACCOUNT_EMAIL',
 'auth_method' => 'json_key',
 'json_keyfile' => 'JSON_KEYFILE_PATH',
 'schema_dir' => '/var/tmp/embulk/schema',
 'config_dir' => '/var/tmp/embulk/config'
}

client = Naginegi::EmbulkRunner.new
client.generate_config(config)
client.run(config)
```

```bash
ruby sample.rb
```

#### using key values
```ruby
[sample.rb]
require 'naginegi'

json_key = {
  "type" => "...",
  "project_id" => "...",
  "private_key_id" => "...",
  "private_key" => "...",
  ...
}

config = {
 'project_id' => 'BIGQUERY_PROJECT_ID',
 'service_email' => 'SERVICE_ACCOUNT_EMAIL',
 'auth_method' => 'json_key',
 'json_key' => json_key,
 'schema_dir' => '/var/tmp/embulk/schema',
 'config_dir' => '/var/tmp/embulk/config'
}

client = Naginegi::EmbulkRunner.new
client.generate_config(config)
client.run(config)
```

```bash
ruby sample.rb
```

## Features
### process status
`Naginegi` returns process status as boolean.  
If all tables are succeed, then returns `true`, else `false` .  
It is useful to control system flow.

```ruby
process_status = Naginegi::EmbulkClient.new.run(config)
exit 1 unless process_status
```

### narrow tables
You can narrow actual target tables from `table.yml` for test or to retry.  
If no target tables is given, `Naginegi` will execute all tables.

```ruby
# in case, all tables are ['users', 'purchases', 'items']
target_tables = ['users', 'purchases']
Naginegi::EmbulkClient.new.run(config, target_tables)
```

### retry
You can set retry count.  
If any table failed, only failed table will be retried until retry count.  
If no retry count is given, `Naginegi` dosen't retry.

```ruby
# 2 times retry will execute
Naginegi::EmbulkClient.new.run(config, [], 2)
```

### SQL condition
If you set `condition` to a table in `table.yml` , SQL is generated like below.  
It is useful for large size table.

```yml
[table.yml]
production:
  tables:
    - name: users
    - name: events
      conditon: created_at < CURRENT_DATE()
```

```sql
SELECT * FROM users
SELECT * FROM events WHERE created_at < CURRENT_DATE()
```

### daily snapshot
BigQuery supports table wildcard expression of a specific set of daily tables, for example, `sales20150701` .  
If you need daily snapshot of a table for BigQuery, use `daily_snapshot` option to `database.yml` or `table.yml` like below.  
`daily_snapshot` option effects all tables in case of  `database.yml` .  
On the other hand, only target table in `table.yml` .  
**Daily part is determined by execute date.**

```yml
[database.yml]
production:
  host: localhost
  username: root
  password: pswd
  database: production
  bq_dataset: mysql
  daily_snapshot: true
```

```yml
[table.yml]
production:
  tables:
    - name: users
    - name: events
      daily_snapshot: true
    - name: hobbies

Only `events` is renamed to `eventsYYYYMMDD` for BigQuery.
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/naginegi/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
