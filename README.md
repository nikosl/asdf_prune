# asdf_prune

Usage: asdf-prune [COMMAND] [ARGUMENT]

Clean up asdf packages

Commands:

  help            show this help
  list            list installed versions of a plugin, default action
  list [plugin]   list available versions of a plugin
  purge [plugin]  remove all but the global or latest version of a plugin
  purge all       remove all but the global or latest version of each plugin
  version         show version

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
gleam run -m birdie review # Review failed test snapshots
gleam run -m gleescript -- --out build/asdf-prune # Package project
```
