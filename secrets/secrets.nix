# agenix recipient list. Used only by the `agenix` CLI (run `agenix -e <name>.age` from this directory).
# Encrypted *.age files are safe to commit; plaintext must never be added here.
#
# Add each host's public key (`cat /etc/ssh/ssh_host_ed25519_key.pub`) and your personal key
# so secrets stay decryptable if a machine is lost.
let
  savage = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICGysUeEAw5im/AUzTZ4+SaMNh6QT0FeZaEfwPMQVP5B";

  hosts = [ savage ];
in
{
  # "example-secret.age".publicKeys = hosts;
}
