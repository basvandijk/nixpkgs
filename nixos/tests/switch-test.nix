# Test configuration switching.

import ./make-test-python.nix ({ pkgs, ...} : {
  name = "switch-test";
  meta = with pkgs.lib.maintainers; {
    maintainers = [ gleber ];
  };

  nodes = {
    machine = { pkgs, ... }: {
      users.mutableUsers = false;

      systemd.services.oneshotRemainAfterExit = {
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.hello}/bin/hello"
        };
      };
    };
    other = { ... }: {
      users.mutableUsers = true;

      systemd.services.oneshotRemainAfterExit = {
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          # This change should cause the service to be restarted:
          ExecStart = "${pkgs.hello}/bin/hello -g 'I got restarted'"
        };
    };
  };

  testScript = {nodes, ...}: let
    originalSystem = nodes.machine.config.system.build.toplevel;
    otherSystem = nodes.other.config.system.build.toplevel;

    # Ensures failures pass through using pipefail, otherwise failing to
    # switch-to-configuration is hidden by the success of `tee`.
    stderrRunner = pkgs.writeScript "stderr-runner" ''
      #! ${pkgs.runtimeShell}
      set -e
      set -o pipefail
      exec env -i "$@" | tee /dev/stderr
    '';
  in ''
    machine.succeed(
        "${stderrRunner} ${originalSystem}/bin/switch-to-configuration test"
    )
    machine.succeed(
        "${stderrRunner} ${otherSystem}/bin/switch-to-configuration test"
    )
    machine.wait_until_succeeds(
        "journalctl -u oneshotRemainAfterExit | grep 'I got restarted'"
    )
  '';
})
