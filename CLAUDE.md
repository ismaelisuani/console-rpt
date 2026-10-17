# console-rpt

Web dispatch console (Rails 8) for RLink radio servers running
[asterisk-rpt](https://github.com/ismaelisuani/asterisk-rpt): Asterisk
certified 22.8 with the RLink app_rpt. Local checkout of that repo:
`~/rlink/asterisk22-rpt`.

## Language

- Everything in the repository is in English: code, identifiers, database
  tables and columns, comments, commit messages, documentation, test names,
  log messages. Nothing in Spanish.
- The user interface is translated to Spanish (`es`), English (`en`) and
  Portuguese (`pt-BR`). Every user-facing string goes through Rails I18n:
  views, flash messages, validation errors, mailers, page titles, Stimulus
  controllers (strings passed from the server or from a translated JSON), enum
  labels. No hardcoded user-facing text anywhere.
- A new key is added to the three locale files in the same change. `i18n-tasks`
  (missing and unused keys) must pass.
- Each user picks their locale; the default is `es`.

## Domain

- **Server**: an asterisk-rpt host (name, address, AMI port and credentials,
  WebRTC endpoint). A radio always belongs to one server; servers can be at
  different addresses.
- **Radio**: an app_rpt node on a server (node number, name, ...). Dispatch
  works on radios: live status, listen, PTT, connect and disconnect.
- **User** with **roles and permissions**: what each user can see and do, and on
  which radios.
- **Unit**: maps a unit ID decoded by app_rpt (ID + decoder: MOTOTRBO, P25,
  MDC1200, DTMF, selcall) to a vehicle or person, so the UI shows who is
  talking instead of the number (radio tile, activity log, recordings). The
  same number can exist under two decoders. Unknown IDs are shown as
  unregistered, with a quick way to add them; bulk import from a spreadsheet.
- **Recording**: the air archive of the radios (audio plus the metadata that
  app_rpt writes: direction, unit ID, decoder, link).

## Integration with asterisk-rpt

- Live state comes from the AMI `RptEvent` events (`RPTKEY`, `UNITID`,
  `LINKS`); commands go through the AMI `Command` action (`rpt fun`,
  `rpt lstats`, ...). See the asterisk-rpt README, section "Eventos AMI".
- The console never requires changes to the wire formats that the existing RLink
  consoles use (`RPTEVENT` text, XNL, archive `.txt`). If a feature needs
  something new from app_rpt, ask first.
- AMI credentials are stored encrypted (Active Record encryption).

## Stack

Rails 8 defaults unless decided otherwise: PostgreSQL, Hotwire (Turbo,
Stimulus), importmap, Propshaft, Solid Queue / Cache / Cable, the built-in
authentication generator, Minitest. Ask before adding a JavaScript build
step or a large dependency.

## Dispatch screen

Agreed layout (mockup in the proposal PDF): top bar with the menu, a WebRTC
SIP phone on the left (can be hidden), and a grid of radio tiles (4, 6 or 9
per screen, by group) with an activity log below. Each tile shows:

- Audio state: incoming audio (green border, live level meter, duration),
  no audio (idle, last activity), transmitting (red border, who), and
  disconnected / server down.
- Mode: operation (listen and talk) or listen only.
- Who is talking (from Unit) and the decoded ID; active links (monitor-only
  links marked differently), click to disconnect one.
- Per-radio volume slider and mute, plus listen all / mute all.
- Connect / disconnect, link to another radio, and a hold-to-talk PTT (mouse or
  space bar; several selected radios transmit together). PTT is disabled when
  not connected and shown locked ("no permission") when the user cannot
  transmit on that radio.

## Deployment

The console runs on the same host as Asterisk, in Docker with Kamal, with
PostgreSQL on that host. That server's `/etc/asterisk` (the console's own
included radio file) and air archive are bind-mounted; other servers are
reached over AMI and SSH (remote recordings are synced to the console's
disk).

## Development

- `bin/dev-db` starts the development PostgreSQL (Docker, 127.0.0.1:5433,
  see `config/database.yml`); then `bin/rails db:prepare` (seeds create the
  base roles and `admin@example.com` / `change-me-now`).
- `bin/dev` runs the web server on port 3100, the Tailwind watcher and
  `bin/ami` (the AMI listener: one connection per active server, applies the
  `RptEvent` events through `RadioState` and broadcasts with
  `DispatchBroadcast`). `bin/ami` does not reload code: restart it after
  changing `app/models/ami` or `RadioState`.
- Live updates are Turbo Streams, one stream per radio and locale (the HTML is
  translated). Action Cable uses PostgreSQL in development because the
  broadcasts come from the `bin/ami` process.
- Before committing: `bin/rails test`, `bin/rubocop`, `bin/brakeman`,
  `bundle exec i18n-tasks missing` and `unused`.
- Test server: the multipass VM `rpt` of asterisk-rpt (two nodes, simulators
  in `/var/spool/asterisk/rpt-test`), AMI user `console`.

## Status

Done: users, roles and permissions, radio groups and access levels, servers,
radios, units (with CSV import), the dispatch screen with live state, unit
names, links (link and unlink from the console) and the activity log.

Next: WebRTC audio (listen, volume, PTT with app_rpt phone mode `*99` / `#`)
and the SIP phone, recordings (air archive), radio configuration on the
server, Kamal deployment.
