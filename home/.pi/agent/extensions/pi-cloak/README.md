# pi-cloak

Pi extension that masks secrets in `read` tool results before they enter model context.

Default rules cover common JSON credential fields, dotenv-style files, `*.vars*`, and secret fields in `config.toml`. Configure additional or replacement rules in `~/.pi/agent/cloak.json` with `patterns`.

Use `/cloak-status` to confirm whether cloaking is enabled and how many rules loaded.
