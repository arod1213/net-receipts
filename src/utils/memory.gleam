import gleam/erlang/atom
import gleam/io

@external(erlang, "erlang", "memory")
fn erlang_memory() -> List(#(atom.Atom, Int))

pub fn log_memory(label: String) {
  let mem = erlang_memory()
  io.println(label <> ":")
  echo mem as "MEMORY"
}
