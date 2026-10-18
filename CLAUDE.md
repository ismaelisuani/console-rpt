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
- Each user picks their locale (default `es`) and a dark (default) or light
  theme, switched from the top bar. Colors are CSS variables: use the palette
  utilities (`bg-canvas`, `text-ink`, `text-rx-ink`, ...) and define every new
  color for both themes in `app/assets/tailwind/application.css`.
- Brand: RLink blue `#1d50a0` (accent) and green `#62b92c` (reception).
  `brand_logo` shows the logo (or the "r" mark) in the version for the
  theme (`app/assets/images/rlink-*.png`, `-dark` with the blue made light);
  favicons in `public/` come from the mark.

## Code conventions

- **Models use concerns.** A model file declares associations, validations,
  scopes and its `include`s; its behavior lives in concerns under
  `app/models/<model>/` (`User::RadioAccess`, `Radio::LiveState`, ...). Shared
  concerns go in `app/models/concerns/`. Processes that involve several models
  are concerns of the model that owns them; plain classes only for
  infrastructure (the AMI connection).
- **Controllers only have CRUD actions**: `index`, `show`, `new`, `create`,
  `edit`, `update`, `destroy`. Anything else is a resource of its own with its
  own controller (`Radios::LinksController#create`, not
  `RadiosController#link`). Controllers stay thin: params, authorization, one
  call to the model, the response.
- **Views use helpers.** Logic that decides what to show (labels, states,
  CSS classes, permissions of a tile) goes in helpers; views and partials hold
  markup and helper calls.

- **Every list is paginated**: `Model...paginate(params[:page])` (the
  `Paginatable` concern of `ApplicationRecord`) and `pagination_nav(@page)` in
  the view.
- **Full width and responsive**: pages use the whole width; every screen works
  on phones (one column, menu button), tablets and desktops. Check the three
  sizes when changing a screen.

## Domain

- **Server**: an asterisk-rpt host (name, address, AMI port and credentials,
  WebRTC endpoint). A radio always belongs to one server; servers can be at
  different addresses.
- **Radio**: an app_rpt node on a server (node number, name, ...). Dispatch
  works on radios: live status, listen, PTT, connect and disconnect.
- **User** with **roles and permissions**: users sign in with their username or
  their email address; the email address is optional (`User::Authentication`).
  Also what each user can see and do, and on
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
- The board (wide screens): rows of equal height; each tile has a column, a
  row and a size in cells. Drag a tile by its header to any cell (another
  radio's side swaps them, its middle links them); resize from the corner.
  Each user's board is saved per radio group (`DispatchLayout`) and can be
  reset. On small screens tiles follow row/column order.
- Links on screen (`links_controller.js`): linked tiles are framed and joined
  by an animated seam (neighbours) or line (far apart) with a chain button
  that unlinks them; dropping a tile in the middle of another links them.
  The link data comes from each tile's live state (`data-links`).
- Focus: a click or the arrows (a control inside a tile keeps it focused);
  the focused tile has a thick frame and a "Space" tag. Space, while held, is PTT on the focused radio;
  Shift + Space (or the big button) is the group PTT on the included radios
  (each tile has a toggle). Space never scrolls.
- The phone (width) and the activity log (height) are resized with the same
  corner mark as the tiles; their sizes are remembered in the browser.
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
  base roles and the user `admin` / `change-me-now`).
- `bin/dev` runs the web server on port 3100, the Tailwind watcher,
  `bin/jobs` (Solid Queue: `RecordingsSyncJob` every minute, see
  `config/recurring.yml`) and `bin/ami` (the AMI listener: one connection per active server, applies the
  `RptEvent` events with `Radio::LiveState` / `Radio::Links`, which log
  `RadioEvent`s and broadcast through `Radio::Broadcasting` and
  `RadioEvent::Broadcasting`). `bin/ami` does not reload code: restart it
  after changing `app/models/ami` or the radio concerns.
- Live updates are Turbo Streams, one stream per radio and locale (the HTML is
  translated). Action Cable uses PostgreSQL in development because the
  broadcasts come from the `bin/ami` process.
- Before committing: `bin/rails test`, `bin/rubocop`, `bin/brakeman`,
  `bundle exec i18n-tasks missing` and `unused`.
- Test server: the multipass VM `rpt` of asterisk-rpt (two nodes, simulators
  in `/var/spool/asterisk/rpt-test`), AMI user `console`, WebRTC
  `ws://10.246.105.221:8088/ws` (plain ws is allowed because the console runs
  on http://127.0.0.1; production needs wss with a real certificate).

## Status

Done: users, roles and permissions, radio groups and access levels, servers,
radios, units (with CSV import), the dispatch screen with live state, unit
names, links (link and unlink from the console), the activity log, and WebRTC
audio: the browser calls `sip:<node>@<server>` through the server's
`webconsole` endpoint with a signed `X-Console-Token` (`Radio::ConsoleCalls`), lands in
`Rpt(node|S)` (operate: simplex phone mode, PTT = `*` / `##` as short
RFC 4733 DTMF; mode P with `*99` is slow and can leave the radio keyed) or
`Rpt(node|Pm)`
(listen only). Server side: `web-console/` in asterisk-rpt; the package needs
SRTP (asterisk-rlink rlink2). JsSIP is vendored as one module
(`script/vendor-jssip`).

Recordings: `Server::Recordings` imports each server's air archive (`.txt` +
GSM `.WAV` written by app_rpt, local times in the server's time zone): read in
place on the local server, copied with rsync over SSH from the others (into
`storage/archives`). `Recording::Audio` converts to PCM WAV with sox for the
browser (`storage/playable`). New recordings are looked for right after a radio
stops receiving or transmitting (and every minute); open recordings pages
refresh by themselves (Turbo refresh with morph). The Docker image needs sox, rsync and ssh.

Phone: every user with the `phone` permission has an extension
(`User::SipAccount`: next free from CONSOLE_EXTENSIONS, 200-299 by default,
editable) and a generated SIP password. `Server::UserExtensions` writes their
PJSIP endpoints and dialplan (`pjsip_console_users.conf`,
`extensions_console_users.conf`, included by asterisk-rpt's web-console
files) on the phone server (in place if local, over SSH if remote) and
reloads Asterisk, after users or roles change (`ProvisionUserExtensionsJob`).
The dispatch phone registers the user's extension (`lib/phone_agent.js`):
status dot, incoming calls with ring/answer/reject, calls to other
dispatchers' extensions, else out through `[console-phone-out]`. Shared
address book (`Contact`) with per-user favorites in the phone.

Next: transfer, calls from the site's PBX, radio configuration on the
server, Kamal deployment.
