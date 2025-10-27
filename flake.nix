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

        # Ansible tools
        ansibleTools = with pkgs; [
          ansible
          ansible-lint
        ];

        # Cloud provider CLIs
        cloudTools = with pkgs; [
          awscli2
          azure-cli
          google-cloud-sdk
        ];

        # Security and Authentication tools
        securityTools = with pkgs; [
          gnupg
          pinentry_mac
          yubikey-manager
          yubikey-personalization
          pcsctools
          openssl
          opensc
          krb5
          libkrb5
          trivy
          checkov
          semgrep
        ];

        # Container tools
        containerTools = with pkgs; [
          docker
          docker-compose
          dive
          skopeo
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
        ];

      in
      {
        devShells.default = pkgs.mkShell {
          name = "terraforming-again-dev";

          buildInputs = goTools ++ terraformTools ++ kubernetesTools ++ ansibleTools
            ++ cloudTools ++ securityTools ++ containerTools ++ devTools;

          shellHook = ''
            echo "🚀 Entering Terraforming Again development environment"
            echo ""
            echo "📦 Tool Versions:"
            echo "  Go:         $(go version | awk '{print $3}')"
            echo "  OpenTofu:   $(tofu version 2>/dev/null | head -1 | awk '{print $2}' || echo 'not available')"
            echo "  kubectl:    $(kubectl version --client --short 2>/dev/null | awk '{print $3}' || echo 'not available')"
            echo "  Ansible:    $(ansible --version 2>/dev/null | head -1 | awk '{print $3}' || echo 'not available')"
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

            # Setup git configuration for this project
            if ! git config user.name >/dev/null 2>&1; then
              echo "📝 Setting up git configuration..."
              git config user.name "usualsuspectx"
              git config user.email "blind3dd@gmail.com"
              git config user.signingkey "CDC126861493EA959E66EA7DB712F8BABBAF0120"
              git config commit.gpgsign true
              git config tag.gpgsign true
              git config core.editor "$(which nano)"
              git config gpg.program "$(which gpg)"
              echo "✅ Git configuration applied"
            fi
            
            # Setup GPG for YubiKey signing
            export GPG_TTY=$(tty)
            export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
            
            # Ensure gpg-agent is running with proper pinentry
            if ! pgrep -x gpg-agent >/dev/null; then
              gpgconf --kill gpg-agent 2>/dev/null || true
              gpg-agent --daemon --enable-ssh-support >/dev/null 2>&1 || true
            fi
            
            # Test GPG/YubiKey
            if gpg --card-status >/dev/null 2>&1; then
              echo "✅ YubiKey detected and accessible"
            else
              echo "⚠️  YubiKey not detected - plug in and try: gpg --card-status"
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
            ln -sf $(which tofu) .nix/bin/terraform 2>/dev/null || true
            ln -sf $(which kubectl) .nix/bin/kubectl 2>/dev/null || true
            ln -sf $(which ansible) .nix/bin/ansible 2>/dev/null || true
            ln -sf $(which aws) .nix/bin/aws 2>/dev/null || true
            ln -sf $(which az) .nix/bin/az 2>/dev/null || true

            # Add OpenTofu to PATH for terraform compatibility
            if command -v tofu >/dev/null 2>&1; then
                alias terraform='tofu'
                echo "✅ OpenTofu available (terraform commands work)"
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

