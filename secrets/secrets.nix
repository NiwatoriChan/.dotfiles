# agenix recipient list. Used only by the `agenix` CLI (run `agenix -e <name>.age` from this directory).
# Encrypted *.age files are safe to commit; plaintext must never be added here.
#
# `./nu init-secrets` fills in `user` below. Add each host's public key
# (`cat /etc/ssh/ssh_host_ed25519_key.pub`) so secrets stay decryptable per machine.
let
  user = "ssh-ed25519 REPLACE_ME"; # USER_SSH_KEY

  savage = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICGysUeEAw5im/AUzTZ4+SaMNh6QT0FeZaEfwPMQVP5B";

  recipients = [ user savage ];
in
{
  # "example-secret.age".publicKeys = recipients;
}
