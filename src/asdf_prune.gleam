import argv
import asdf_prune/asdf
import asdf_prune/error.{exit_map, exit_success, exit_unk_failure}
import asdf_prune/internal/cmd
import asdf_prune/view
import gleam/bool
import gleam/result
import spinner

pub fn main() {
  use <- bool.lazy_guard(when: cmd.is_installed(), otherwise: fn() {
    view.display_not_found()
    exit_unk_failure()
  })

  case argv.load().arguments {
    ["list", plg] -> {
      use _ <- view.with_spinner("Load plugin versions\n")
      show_versions(plg)
    }
    [] | ["list"] -> {
      use _ <- view.with_spinner("Load plugins\n")
      show_plugins()
    }
    ["purge", "all"] -> {
      use s <- view.with_spinner("Cleanup plugin\n")
      use l, r <- purge()
      let #(v, u) = r

      s
      |> spinner.set_text(
        "Plugin: " <> l <> " removed: " <> v <> " status: " <> res_to_string(u),
      )
    }
    ["purge", plug] -> {
      use s <- view.with_spinner("Cleanup plugin\n")
      use r <- cleanup_plugin(plug)
      let #(v, u) = r
      s
      |> spinner.set_text("Removed: " <> v <> " status: " <> res_to_string(u))
    }
    ["version"] -> {
      view.display_version()
      exit_success()
    }
    ["help"] -> {
      view.display_help()
      exit_success()
    }
    _ -> {
      view.display_help()
      exit_unk_failure()
    }
  }
}

fn show_versions(plugin: String) -> Nil {
  asdf.new()
  |> asdf.available(plugin)
  |> result.map(view.display_plugin)
  |> view.inspect_err
  |> exit_map
}

fn show_plugins() -> Nil {
  asdf.new()
  |> asdf.plugins()
  |> result.map(view.display_plugins)
  |> view.inspect_err
  |> exit_map
}

fn cleanup_plugin(
  plugin: String,
  f: fn(#(String, error.Result(String))) -> Nil,
) -> Nil {
  asdf.new()
  |> asdf.cleanup_plugin(plugin, f)
  |> result.map(view.display_cleanup_plugin(plugin, _))
  |> view.inspect_err
  |> exit_map
}

fn purge(f: fn(String, #(String, error.Result(String))) -> Nil) -> Nil {
  asdf.new()
  |> asdf.purge(f)
  |> result.map(view.display_purge)
  |> view.inspect_err
  |> exit_map
}

fn res_to_string(r: error.Result(String)) -> String {
  case r {
    Ok(_) -> "Ok"
    Error(_) -> "Error"
  }
}
