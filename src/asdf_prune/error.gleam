import shellout
import snag

pub type Result(t) =
  snag.Result(t)

pub fn new(err: String) -> Result(_) {
  snag.error(err)
}

pub fn exit_map(r: Result(_)) -> Nil {
  case r {
    Ok(_) -> exit_success()
    Error(_) -> exit_unk_failure()
  }
}

pub fn exit_success() -> Nil {
  exit(0)
}

pub fn exit_unk_failure() -> Nil {
  exit(1)
}

pub fn exit(rc: Int) -> Nil {
  shellout.exit(rc)
}
