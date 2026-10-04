# Stamps every home generation with the flake revision it was built from, so
# the system can tell a self-managed home that has fallen behind (or is built
# from something else entirely) from one that is current.
{ inputs, ... }: {
  xdg.configFile."org/revision".text =
    inputs.self.rev or inputs.self.dirtyRev or "unknown";
}
