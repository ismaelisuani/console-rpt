# console-rpt

Web dispatch console for RLink radio servers running
[asterisk-rpt](https://github.com/ismaelisuani/asterisk-rpt): live state of
the radios, who is talking, links, PTT and recordings. Rails 8, PostgreSQL,
Hotwire. User interface in Spanish, English and Portuguese.

## Development

```sh
bin/dev-db             # PostgreSQL in Docker on 127.0.0.1:5433
bin/rails db:prepare   # schema and seeds (user admin / change-me-now)
bin/dev                # http://127.0.0.1:3100, CSS watcher and the AMI listener
```

Each Asterisk server needs an AMI user for the console, with `read = call`
and `write = command,system` (manager.conf), reachable from the console.

## Checks

```sh
bin/rails test
bin/rubocop
bin/brakeman
bundle exec i18n-tasks missing && bundle exec i18n-tasks unused
```
