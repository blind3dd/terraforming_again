{
  description = "Terraforming Again - Multi-cloud Kubernetes infrastructure with CAPI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  nixConfig = {
    # Binary cache configuration for arm64 (Apple Silicon)
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
    experimental-features = [ "nix-command" "flakes" ];
    system = "aarch64-darwin";
    allowUnfree = true;
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Go development tools
        goTools = with pkgs; [
          go  # Latest stable Go version
          gopls
          go-tools
          golangci-lint
          delve
          gotools
        ];

        # Terraform/OpenTofu tools
        terraformTools = with pkgs; [
          opentofu
          terraform-ls
          tflint
          terragrunt
        ];

        # Kubernetes and ClusterAPI tools
        kubernetesTools = with pkgs; [
          kubectl
          kubernetes-helm
          kustomize
          k9s
          kind
          minikube
          clusterctl
          talosctl
        ];

        # Ansible tools (ansible-vault is included in the ansible package)
        ansibleTools = with pkgs; [
          ansible
          ansible-lint
        ];

        # Cloud provider CLIs
        cloudTools = with pkgs; [
          awscli2
          azure-cli
          google-cloud-sdk
          aws-vault
        ];

        # Security and Authentication tools
        securityTools = with pkgs; [
          gnupg
          pinentry_mac
          yubikey-manager
          yubikey-personalization
          pcsc-tools
          openssl
          opensc
          krb5
          libkrb5
          trivy
          # checkov - removed due to sbcl build issues, use in CI/CD instead
          semgrep
        ];

        # Container tools
        containerTools = with pkgs; [
          docker
          docker-compose
          dive
          skopeo
        ];

        # Python tools
        pythonTools = with pkgs; [
          python3
          python3Packages.pip
          python3Packages.setuptools
          python3Packages.wheel
          python3Packages.cryptography
          python3Packages.boto3
          python3Packages.botocore
        ];

        # Additional development tools
        devTools = with pkgs; [
          git
          gh
          curl
          wget
          jq
          yq-go
          ripgrep
          fd
          fzf
          bat
          eza
          direnv
          nix-direnv
          watchman
          pre-commit
          gnused      # GNU sed (gsed on macOS)
          gawk        # GNU awk (gawk on macOS)
          coreutils   # GNU coreutils (gdate, gls, etc. on macOS)
        ];

      in
      {
        devShells.default = pkgs.mkShell {
          name = "terraforming-again-dev";

          buildInputs = goTools ++ terraformTools ++ kubernetesTools ++ ansibleTools
            ++ cloudTools ++ securityTools ++ containerTools ++ pythonTools ++ devTools;

          shellHook = ''
            # Fix TERM for proper vim syntax highlighting
            # Only override if TERM is unset or set to 'dumb' (which disables colors)
            if [ -z "$TERM" ] || [ "$TERM" = "dumb" ]; then
              # Detect terminal type - prefer xterm-256color for color support
              if [ -n "$ITERM_SESSION_ID" ] || [ -n "$VSCODE_INJECTION" ]; then
                export TERM=xterm-256color
              elif [ -n "$TMUX" ]; then
                export TERM=screen-256color
              else
                # Default to xterm-256color for modern terminals
                export TERM=xterm-256color
              fi
            fi

            echo "Entering Terraforming Again development environment"
            echo ""
            echo "Tool Versions:"
            echo "  Go:         $(go version | awk '{print $3}')"
            echo "  OpenTofu:   $(tofu version 2>/dev/null | head -1 | awk '{print $2}' || echo 'not available')"
            echo "  kubectl:    $(kubectl version --client --short 2>/dev/null | awk '{print $3}' || echo 'not available')"
            echo "  Ansible:    $(ansible --version 2>/dev/null | head -n1 | awk '{print $3}' | cut -d "]" -f 1 || echo 'not available')"
            echo "  AWS CLI:    $(aws --version 2>/dev/null | awk '{print $1}' | cut -d'/' -f2 || echo 'not available')"
            echo "  Azure CLI:  $(az version 2>/dev/null | jq -r '."azure-cli"' || echo 'not available')"
            echo ""

            # Setup VSCode/Cursor settings if not already installed
            if [ ! -d ".vscode" ]; then
              echo "📝 Installing VSCode settings and extensions..."
              mkdir -p .vscode
              cp -n .nix/dotfiles/ide/settings.json .vscode/settings.json 2>/dev/null || echo "Settings already exist"
              cp -n .nix/dotfiles/ide/extensions.json .vscode/extensions.json 2>/dev/null || echo "Extensions already exist"
              echo "✅ VSCode configuration installed"
            fi

            # Git identity + YubiKey signing from ~/.config/git/yubikey-signing.env
            git config --local user.name "usualsuspectx" 2>/dev/null || true
            git config --local user.email "blind3dd@gmail.com" 2>/dev/null || true
            if [[ -f ./.nix/dotfiles/gpg/yubikey-shell-hook.sh ]]; then
              source ./.nix/dotfiles/gpg/yubikey-shell-hook.sh
            fi

            # Ensure tools are available in PATH
            export PATH="$PATH:/nix/var/nix/profiles/default/bin"

            # Set Go environment for proper tooling and navigation
            export GOPATH="$HOME/Development/go"
            export GO111MODULE="on"
            export CGO_ENABLED="0"

            # Go cache configuration (separate from workspace)
            export GOMODCACHE="$HOME/.cache/go/mod"
            export GOCACHE="$HOME/.cache/go/build"
            export GOSUMDB="sum.golang.org"

            # Add workspace bin to PATH for custom tools
            export PATH="$PWD/.nix/bin:$PATH"

            # Create symlinks for tools in .nix/bin
            mkdir -p .nix/bin
            ln -sf $(which go) .nix/bin/go 2>/dev/null || true
            ln -sf $(which gopls) .nix/bin/gopls 2>/dev/null || true
            # Create terraform symlink (alias to tofu) - ensure it's in PATH
            if command -v tofu >/dev/null 2>&1; then
                ln -sf $(which tofu) .nix/bin/terraform 2>/dev/null || true
                # Also create a wrapper script for better compatibility
                cat > .nix/bin/terraform-wrapper << 'EOF'
#!/usr/bin/env bash
# Terraform wrapper that calls OpenTofu
exec tofu "$@"
EOF
                chmod +x .nix/bin/terraform-wrapper
                # Use wrapper as primary terraform command
                ln -sf .nix/bin/terraform-wrapper .nix/bin/terraform 2>/dev/null || true
            fi
            ln -sf $(which kubectl) .nix/bin/kubectl 2>/dev/null || true
            ln -sf $(which ansible) .nix/bin/ansible 2>/dev/null || true
            ln -sf $(which aws) .nix/bin/aws 2>/dev/null || true
            ln -sf $(which az) .nix/bin/az 2>/dev/null || true

            # Add OpenTofu to PATH for terraform compatibility
            # Alias and function for better shell integration
            if command -v tofu >/dev/null 2>&1; then
                alias terraform='tofu'
                terraform() {
                    tofu "$@"
                }
                echo "✅ OpenTofu available (terraform commands work)"
                echo "   terraform → tofu (alias and function)"
            fi

            # Alias GNU tools for macOS compatibility
            if command -v gsed >/dev/null 2>&1; then
                alias sed='gsed'
                echo "✅ GNU sed available (sed → gsed alias)"
            fi
            
            if command -v gawk >/dev/null 2>&1; then
                alias awk='gawk'
                echo "✅ GNU awk available (awk → gawk alias)"
            fi
            
            if command -v gdate >/dev/null 2>&1; then
                alias date='gdate'
                echo "✅ GNU date available (date → gdate alias)"
            fi

            # Setup AWS profile helper
            if [ -f "hack/assume-role.sh" ]; then
              alias aws-assume='./hack/assume-role.sh'
              echo "💡 Use 'aws-assume' to assume AWS roles"
            fi

            # Kubernetes context helper
            if command -v kubectl >/dev/null 2>&1; then
              alias k='kubectl'
              alias kx='kubectl config use-context'
              alias kns='kubectl config set-context --current --namespace'
              echo "💡 Kubectl aliases: k, kx (context), kns (namespace)"
            fi

            # ClusterAPI helper
            if command -v clusterctl >/dev/null 2>&1; then
              echo "💡 ClusterAPI available - use: clusterctl init"
            fi

            echo ""
            echo "✅ Development environment ready!"
            echo "💡 Run 'nix flake update' to update dependencies"
            echo "💡 Run './hack/fix-go-navigation.sh' if gopls isn't working"
            echo ""
          '';

          # Environment variables
          env = {
            GOPROXY = "https://proxy.golang.org,direct";
            GOSUMDB = "sum.golang.org";
            GOTOOLCHAIN = "local";
            # Go paths for proper tooling and navigation
            GOPATH = "/Users/usualsuspectx/Development/go";
            GO111MODULE = "on";
            CGO_ENABLED = "0";
            # Go cache configuration (separate from workspace)
            GOMODCACHE = "/Users/usualsuspectx/.cache/go/mod";
            GOCACHE = "/Users/usualsuspectx/.cache/go/build";
            # Git configuration
            GIT_AUTHOR_NAME = "usualsuspectx";
            GIT_AUTHOR_EMAIL = "blind3dd@gmail.com";
            GIT_COMMITTER_NAME = "usualsuspectx";
            GIT_COMMITTER_EMAIL = "blind3dd@gmail.com";
            # Project environment
            PROJECT_NAME = "terraforming_again";
            # Disable telemetry
            CHECKPOINT_DISABLE = "1";
            DO_NOT_TRACK = "1";
          };
        };
      });
}

