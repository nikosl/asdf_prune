import asdf_prune/asdf
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import gleam_community/ansi
import snag
import spinner

const hex_version = "1.0.0"

pub fn display_version() -> Nil {
  hex_version |> io.print
}

pub fn display_help() -> Nil {
  pprint_help() |> io.print
}

pub fn pprint_help() -> String {
  let commands =
    [
      #("list", "list installed versions of a plugin"),
      #("list <plugin>", "list available versions of a plugin"),
      #(
        "purge <plugin>",
        "remove all but the global or latest version of a plugin",
      ),
      #(
        "purge all",
        "remove all but the global or latest version of each plugin",
      ),
      #("help", "show this help"),
      #("version", "show version"),
    ]
    |> dict.from_list

  let cmd_len =
    commands
    |> dict.keys
    |> list.fold(0, fn(acc, k) { k |> string.length |> int.max(acc) })
    |> int.add(4)

  let cmd_help =
    commands
    |> dict.to_list
    |> list.map(fn(l) {
      let #(cmd, desc) = l

      cmd
      |> ident(2)
      |> string.pad_right(cmd_len, " ")
      |> ansi.green
      |> string.append(desc)
    })

  let help =
    ansi.yellow("Usage: ")
    <> ansi.green("asdf_prune")
    <> " [COMMAND] <ARGUMENT>\n\n"
    <> "Clean up asdf packages\n\n"
    <> ansi.yellow("Version: ")
    <> ansi.green(hex_version)
    <> "\n\n"
    <> ansi.yellow("Commands:\n\n")
    <> cmd_help |> string.join("\n")
    <> "\n"

  help
}

pub fn display_plugin(plugin: asdf.Local) -> Nil {
  plugin |> pprint_plugin |> io.print
}

pub fn pprint_plugin(l: asdf.Local) -> String {
  let h = "\u{1F3AF} Plugin:\n" |> ansi.dim
  let name =
    l.name
    |> ansi.bold
    |> ansi.magenta
    <> "\n"

  let glob =
    l.global
    |> option.map(fn(g) {
      ansi.dim("✨ global: \n") |> ident(2)
      <> ansi.green(g) |> ident(5)
      <> "\n"
    })
    |> option.unwrap("")

  let vers =
    "  \u{1F4E2} available:"
    |> ansi.dim
    <> "\n"
    <> l.available
    |> list.map(fn(v) { ansi.yellow(v) |> ident(5) })
    |> string.join("\n")

  let body = h <> ident(name, 5) <> glob <> vers <> "\n"

  body
}

pub fn display_plugins(plugins: asdf.Plugins) -> Nil {
  plugins |> pprint_plugins |> io.print
}

pub fn pprint_plugins(plg: asdf.Plugins) -> String {
  let h = "\u{1F4E6} Plugins:\n\n" |> ansi.bold |> ansi.magenta
  let c =
    plg
    |> asdf.plugins_to_list
    |> list.map(ident(_, 3))
    |> string.join("\n")
    |> ansi.green

  let body = h <> c <> "\n"

  body
}

pub fn display_cleanup_plugin(name: String, status: asdf.OpStatus) -> Nil {
  name |> pprint_cleanup_plugin(status) |> io.print
}

pub fn pprint_cleanup_plugin(name: String, status: asdf.OpStatus) -> String {
  pprint_cleanup_header() <> pprint_op_status(name, status)
}

pub fn pprint_op_status(name: String, status: asdf.OpStatus) -> String {
  let n = name |> ansi.bold |> ansi.red |> ident(4)

  let c =
    status
    |> dict.to_list
    |> list.map(fn(v) {
      let #(v, s) = v
      case s {
        Ok(_) -> v |> ansi.green |> string.append("Ok" |> ident(4))
        Error(e) ->
          v
          |> ansi.red
          |> string.append("Error: " |> ident(4))
          |> string.append(e |> snag.line_print)
      }
      |> ident(4)
    })
    |> string.join("\n")

  let body = n <> "\n\n" <> c <> "\n"

  body
}

pub fn display_purge(status: dict.Dict(String, asdf.OpStatus)) -> Nil {
  status |> pprint_purge |> io.print
}

pub fn pprint_purge(status: dict.Dict(String, asdf.OpStatus)) -> String {
  let h = pprint_cleanup_header()
  let c =
    status
    |> dict.to_list
    |> list.map(fn(v) {
      let #(n, s) = v
      pprint_op_status(n, s) <> "\n\n"
    })
    |> string.join("\n")

  h <> c
}

fn pprint_cleanup_header() -> String {
  "\u{1F9F9} Cleanup:\n\n" |> ansi.yellow
}

pub fn display_not_found() -> Nil {
  "\u{1F6A8} asdf not found in PATH"
  |> pprint_err_msg
  |> io.print_error
}

fn pprint_err_msg(e: String) -> String {
  e
  |> ansi.red
  |> ansi.bold
}

pub fn inspect_err(err: Result(_, snag.Snag)) -> Result(_, snag.Snag) {
  err
  |> result.map_error(fn(s) {
    snag.pretty_print(s) |> pprint_err_msg |> io.print_error
    s
  })
}

pub fn with_spinner(t: String, cb: fn(spinner.Spinner) -> a) -> a {
  let s =
    spinner.new(t)
    |> spinner.start()
  let res = cb(s)
  spinner.stop(s)

  res
}

fn ident(str: String, i: Int) -> String {
  string.append(spaces(i), str)
}

fn spaces(times: Int) -> String {
  string.repeat(" ", times)
}
