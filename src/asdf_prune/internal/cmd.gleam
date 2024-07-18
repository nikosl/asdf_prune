import asdf_prune/error.{type Result}
import gleam/pair
import gleam/result
import shellout
import snag

const asdf = "asdf"

pub type Cmd {
  Cmd(
    is_installed: fn() -> Bool,
    show_plugins: fn() -> Result(String),
    show_versions: fn(String) -> Result(String),
    remove: fn(String, String) -> Result(String),
  )
}

pub fn is_installed() -> Bool {
  shellout.which(asdf) |> result.is_ok
}

pub fn show_versions(p: String) -> Result(String) {
  let cmd_err = with_context(_, "failed to list versions")

  shellout.command(run: asdf, with: ["list", p], in: ".", opt: [])
  |> result.map_error(cmd_err)
}

pub fn remove(plg: String, version: String) -> Result(String) {
  let cmd_err = with_context(_, "failed to remove version")

  shellout.command(
    run: asdf,
    with: ["uninstall", plg, version],
    in: ".",
    opt: [],
  )
  |> result.map_error(cmd_err)
}

pub fn show_plugins() -> Result(String) {
  let cmd_err = with_context(_, "failed to list plugins")

  shellout.command(run: asdf, with: ["plugin", "list"], in: ".", opt: [])
  |> result.map_error(cmd_err)
}

fn with_context(err: #(_, String), ctx: String) -> snag.Snag {
  err |> pair.second |> snag.new |> snag.layer(ctx)
}

pub fn new() -> Cmd {
  Cmd(
    is_installed: is_installed,
    show_plugins: show_plugins,
    show_versions: show_versions,
    remove: remove,
  )
}
// pub fn cmd_with_show_plugins(c: fn() -> Result(String)) -> Cmd {
//   todo
// }
