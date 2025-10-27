# This file allows direnv to use the flake environment
# It delegates to the flake's devShell

(import (
  let
    lock = builtins.fromJSON (builtins.readFile ./flake.lock);
    flake-compat = fetchTarball {
      url = "https://github.com/edolstra/flake-compat/archive/master.tar.gz";
      sha256 = "0m9grvfsbwmvgwaxvdzv6cmyvjnlww004gfxjvcl806ndqaxzy4j";
    };
  in
  import flake-compat { src = ./.; }
).shellNix)

