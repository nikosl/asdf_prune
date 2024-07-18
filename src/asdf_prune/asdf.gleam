import asdf_prune/error.{type Result}
import asdf_prune/internal/cmd.{type Cmd}
import gleam/bool
import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import snag

pub type OpStatus =
  Dict(String, Result(String))

pub type Asdf {
  Asdf(op: Cmd)
}

pub type Plugins {
  Plugins(List(String))
}

pub type Local {
  Local(name: String, global: Option(String), available: List(String))
}

pub fn versions(name: String) -> Local {
  Local(name: name, global: None, available: [])
}

pub fn with_global(plugin: Local, v: String) -> Local {
  Local(..plugin, global: Some(v))
}

pub fn append_available(plugin: Local, v: String) -> Local {
  Local(..plugin, available: [v, ..plugin.available])
}

pub fn is_available(plugin: Local, version: String) -> Bool {
  plugin.available
  |> list.contains(version)
}

pub fn new() -> Asdf {
  Asdf(op: cmd.new())
}

pub fn plugins(asdf: Asdf) -> Result(Plugins) {
  asdf.op.show_plugins()
  |> result.map(parse_plugins)
}

pub fn available(asdf: Asdf, name: String) -> Result(Local) {
  asdf.op.show_versions(name)
  |> result.map(parse_versions(versions(name), _))
}

pub fn has_plugin(asdf: Asdf, name: String) -> Result(String) {
  asdf
  |> plugins()
  |> result.try(fn(l) {
    let has =
      l
      |> plugins_to_list
      |> list.contains(name)

    case has {
      True -> Ok(name)
      False -> snag.error("plugin not available")
    }
  })
}

fn remove(asdf: Asdf, plg: Local, version: String) -> Result(String) {
  use <- bool.lazy_guard(when: is_available(plg, version), otherwise: fn() {
    snag.error("version not available")
  })
  plg.name |> asdf.op.remove(version)
}

pub fn cleanup_plugin(
  asdf: Asdf,
  plg: String,
  f: fn(#(String, Result(String))) -> Nil,
) -> Result(OpStatus) {
  asdf
  |> has_plugin(plg)
  |> result.try(available(asdf, _))
  |> result.try(fn(p) {
    let cand = p.global |> option.is_some
    let vers = p.available |> list.length

    case cand, vers {
      True, 1 -> snag.error("no versions to remove")
      _, _ -> Ok(p)
    }
  })
  |> result.map(fn(p) { cleanup(asdf, p, f) })
}

pub fn cleanup(
  asdf: Asdf,
  plg: Local,
  f: fn(#(String, Result(String))) -> Nil,
) -> OpStatus {
  case plg.global {
    Some(_) -> plg.available
    None ->
      plg.available
      |> pick_versions
  }
  |> list.map(fn(v) {
    let r = remove(asdf, plg, v)
    let s = #(v, r)
    f(s)

    s
  })
  |> dict.from_list
}

pub fn purge(
  asdf: Asdf,
  f: fn(String, #(String, Result(String))) -> Nil,
) -> Result(Dict(String, OpStatus)) {
  asdf
  |> installed_plugins()
  |> result.map(fn(l) {
    l
    |> list.fold(dict.new(), fn(acc, p) {
      let f = f(p.name, _)
      let r = cleanup(asdf, p, f)

      dict.insert(acc, p.name, r)
    })
  })
}

pub fn installed_plugins(asdf: Asdf) -> Result(List(Local)) {
  asdf
  |> plugins()
  |> result.map(plugins_to_list)
  |> result.try(fn(pl) {
    pl
    |> list.map(available(asdf, _))
    |> result.all
  })
}

pub fn plugins_to_list(p: Plugins) -> List(String) {
  let Plugins(l) = p

  l
}

pub fn pprint_plugins(p: Plugins) -> String {
  let p = p |> plugins_to_list

  p |> string.join("\n")
}

fn pick_versions(l: List(String)) -> List(String) {
  l
  |> list.sort(string.compare)
  |> list.reverse
  |> list.rest
  |> result.unwrap([])
}

fn parse_versions(l: Local, s: String) -> Local {
  s
  |> split_lines
  |> list.fold(l, fn(l, s) {
    let is_active = s |> string.starts_with("*")

    case is_active {
      True -> with_global(l, s |> string.drop_left(1))
      False -> append_available(l, s)
    }
  })
}

fn parse_plugins(s: String) -> Plugins {
  s
  |> split_lines
  |> Plugins
}

fn split_lines(s: String) -> List(String) {
  s
  |> string.split("\n")
  |> list.map(string.trim)
  |> list.filter(fn(s) { !string.is_empty(s) })
}
