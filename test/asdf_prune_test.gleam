import asdf_prune/asdf
import asdf_prune/error.{type Result}
import asdf_prune/internal/cmd
import asdf_prune/view
import birdie
import gleam/dict
import gleam/list
import gleam/pair
import gleeunit

const plugins_out = "elixir
erlang
gleam
nodejs
rebar
"

const erlang_out = "  26.1
  26.2.2
 *27.0.1
  27.0
"

const version_list = ["26.1", "26.2.2", "27.0.1", "27.0"]

const nodejs_empty_out = "  No versions installed
"

pub fn main() {
  gleeunit.main()
}

pub fn show_plugins_test() {
  let asd =
    cmd.Cmd(
      is_installed: fn() { True },
      show_plugins: show_plugins_helper(plugins_out, False),
      show_versions: fn(_) { Ok("asdf") },
      remove: fn(_, _) { Ok("asdf") },
    )
    |> asdf.Asdf()

  let assert Ok(r) =
    asd
    |> asdf.plugins()

  r
  |> view.pprint_plugins
  |> birdie.snap("plugin_list")
}

pub fn show_plugins_empty_test() {
  let asd =
    cmd.Cmd(
      is_installed: fn() { True },
      show_plugins: show_plugins_helper("", False),
      show_versions: fn(_) { Ok("asdf") },
      remove: fn(_, _) { Ok("asdf") },
    )
    |> asdf.Asdf()

  let assert Ok(r) =
    asd
    |> asdf.plugins()

  r
  |> view.pprint_plugins
  |> birdie.snap("plugin_list_empty")
}

pub fn show_versions_empty_test() {
  let asd =
    cmd.Cmd(
      is_installed: fn() { True },
      show_plugins: fn() { Ok("asdf") },
      show_versions: show_versions_helper(
        dict.from_list([#("nodejs", nodejs_empty_out)]),
        False,
      ),
      remove: fn(_, _) { Ok("asdf") },
    )
    |> asdf.Asdf()

  let assert Ok(r) =
    asd
    |> asdf.available("nodejs")

  r
  |> view.pprint_plugin
  |> birdie.snap("no_versions")
}

pub fn show_versions_test() {
  let asd =
    cmd.Cmd(
      is_installed: fn() { True },
      show_plugins: show_plugins_helper(plugins_out, False),
      show_versions: show_versions_helper(
        dict.from_list([#("erlang", erlang_out)]),
        False,
      ),
      remove: fn(_, _) { Ok("asdf") },
    )
    |> asdf.Asdf()

  let assert Ok(r) =
    asd
    |> asdf.available("erlang")

  r
  |> view.pprint_plugin
  |> birdie.snap("erlang_versions")
}

pub fn remove_versions_test() {
  let exp =
    version_list
    |> list.map(pair.new(_, Ok("")))
    |> dict.from_list

  let asd =
    cmd.Cmd(
      is_installed: fn() { True },
      show_plugins: show_plugins_helper(plugins_out, False),
      show_versions: show_versions_helper(
        dict.from_list([#("erlang", erlang_out)]),
        False,
      ),
      remove: remove_helper(exp),
    )
    |> asdf.Asdf()

  let assert Ok(r) =
    asd
    |> asdf.cleanup_plugin("erlang", fn(_) { Nil })

  r
  |> view.pprint_cleanup_plugin("erlang", _)
  |> birdie.snap("erlang_purge")
}

pub fn remove_all_test() {
  let exp =
    version_list
    |> list.map(pair.new(_, Ok("")))
    |> dict.from_list

  let asd =
    cmd.Cmd(
      is_installed: fn() { True },
      show_plugins: show_plugins_helper("\nerlang\n" <> "nodejs\n", False),
      show_versions: show_versions_helper(
        dict.from_list([#("erlang", erlang_out), #("nodejs", nodejs_empty_out)]),
        False,
      ),
      remove: remove_helper(exp),
    )
    |> asdf.Asdf()

  let assert Ok(r) =
    asd
    |> asdf.purge(fn(_, _) { Nil })

  r
  |> view.pprint_purge
  |> birdie.snap("erlang_purge")
}

fn show_plugins_helper(out: String, err: Bool) -> fn() -> Result(String) {
  fn() {
    case err {
      True -> error.new(out)
      False -> Ok(out)
    }
  }
}

fn show_versions_helper(
  out: dict.Dict(String, String),
  err: Bool,
) -> fn(String) -> Result(String) {
  fn(plug) {
    let assert Ok(o) = out |> dict.get(plug)
    case err {
      True -> error.new(o)
      False -> Ok(o)
    }
  }
}

fn remove_helper(
  out: dict.Dict(String, Result(String)),
) -> fn(String, String) -> Result(String) {
  fn(_plug, ver) {
    let assert Ok(o) = out |> dict.get(ver)
    o
  }
}
