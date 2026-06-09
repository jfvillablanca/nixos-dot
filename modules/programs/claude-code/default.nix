# Declarative claude-code: settings, memory, skills, and the env-block
# hooks shipped as a single home-manager Aspect. Skills under
# `./skills/<name>/` are auto-discovered. The module writes its
# settings into `~/.claude/settings.local.json` so Claude Code's
# precedence (settings.json then settings.local.json) lets nix overlay
# without clobbering runtime mutations users make to settings.json
# directly.
#
# claude-code itself comes from a dedicated `nixpkgs-claude-code` input
# (defaulting to `nixos-unstable`) so the CLI tracks fast without
# dragging the rest of `pkgs-master` along. Override the lock pin
# manually when you want a specific upstream commit.
{
  flake-file.inputs.nixpkgs-claude-code.url = "github:nixos/nixpkgs/nixos-unstable";

  flake.modules.homeManager.claudeCode = {
    config,
    lib,
    pkgs,
    inputs,
    ...
  }: let
    cfg = config.myHomeModules.claudeCode;
    jsonFormat = pkgs.formats.json {};
    pkgsClaudeCode = import inputs.nixpkgs-claude-code {
      inherit (pkgs.stdenv.hostPlatform) system;
      config.allowUnfree = true;
    };

    skillsDir = ./skills;
    discoveredSkills =
      if builtins.pathExists skillsDir
      then
        lib.mapAttrs
        (name: _: skillsDir + "/${name}")
        (lib.filterAttrs (_: kind: kind == "directory") (builtins.readDir skillsDir))
      else {};

    # PreToolUse hook that blocks any tool call touching a file path
    # matching `^|/\.env(\.|$)`. Used for Read/Edit/Write where the
    # input is `tool_input.file_path`.
    blockEnvByFilePath = matcher: {
      inherit matcher;
      hooks = [
        {
          type = "command";
          command = ''
            filepath=$(cat | ${pkgs.jq}/bin/jq -r '.tool_input.file_path // ""') && \
            if echo "$filepath" | grep -qE '(^|/)\.env(\.|$)'; then \
              echo '{"decision":"block","reason":"Refusing to ${lib.toLower matcher} .env files. They contain secrets."}'; \
            fi
          '';
        }
      ];
    };
  in {
    options.myHomeModules.claudeCode = {
      enable = lib.mkEnableOption "declarative claude-code (settings + memory + skills + hooks)";

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgsClaudeCode.claude-code;
        defaultText = lib.literalExpression "(import inputs.nixpkgs-claude-code {...}).claude-code";
        description = ''
          claude-code package. Defaults to the dedicated
          `nixpkgs-claude-code` input so the CLI can be bumped
          independently of the rest of the fleet's nixpkgs.
        '';
      };

      settings = lib.mkOption {
        inherit (jsonFormat) type;
        default = {};
        description = ''
          Merged into `~/.claude/settings.local.json`. Claude Code reads
          `settings.json` first then overlays `settings.local.json`, so
          nix-declared keys win at read time without clobbering whatever
          the user has hand-edited in `settings.json`.
        '';
      };

      memory = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = builtins.readFile ./CLAUDE.md;
        defaultText = lib.literalExpression "builtins.readFile ./CLAUDE.md";
        description = "Contents of `~/.claude/CLAUDE.md`. null skips the file.";
      };

      skills = lib.mkOption {
        type = lib.types.attrsOf lib.types.path;
        default = discoveredSkills;
        defaultText = lib.literalExpression "auto-discovered from ./skills/";
        description = ''
          Map of skill-name to source directory. Each entry is recursively
          copied into `~/.claude/skills/<name>/`.
        '';
      };
    };

    config = lib.mkIf cfg.enable {
      # python3 is required by the security-guidance plugin's
      # pattern-warning + diff-review hooks; the plugin picks python3 /
      # python / py -3 off PATH.
      home.packages = [cfg.package pkgs.python3];

      myHomeModules.claudeCode.settings = {
        # Plugins enabled by default for every fleet member.
        # `claude-plugins-official` is Anthropic's built-in marketplace
        # (no extraKnownMarketplaces entry needed); `caveman` ships from
        # a third-party github repo and has to be registered.
        enabledPlugins = {
          "caveman@caveman" = true;
          "security-guidance@claude-plugins-official" = true;
        };

        extraKnownMarketplaces.caveman.source = {
          source = "github";
          repo = "JuliusBrussee/caveman";
        };

        hooks.PreToolUse = [
          (blockEnvByFilePath "Read")
          (blockEnvByFilePath "Edit")
          (blockEnvByFilePath "Write")
          {
            matcher = "Grep";
            hooks = [
              {
                type = "command";
                command = ''
                  input=$(cat) && \
                  path=$(echo "$input" | ${pkgs.jq}/bin/jq -r '.tool_input.path // ""') && \
                  glob=$(echo "$input" | ${pkgs.jq}/bin/jq -r '.tool_input.glob // ""') && \
                  if echo "$path" | grep -qE '(^|/)\.env(\.|$)' || echo "$glob" | grep -qE '\.env'; then \
                    echo '{"decision":"block","reason":"Refusing to grep inside .env files."}'; \
                  fi
                '';
              }
            ];
          }
          {
            matcher = "Glob";
            hooks = [
              {
                type = "command";
                command = ''
                  pattern=$(cat | ${pkgs.jq}/bin/jq -r '.tool_input.pattern // ""') && \
                  if echo "$pattern" | grep -qE '\.env'; then \
                    echo '{"decision":"block","reason":"Refusing to glob for .env files."}'; \
                  fi
                '';
              }
            ];
          }
        ];
      };

      home.file = lib.mkMerge (
        [
          {".claude/settings.local.json".source = jsonFormat.generate "settings.local.json" cfg.settings;}
        ]
        ++ lib.optional (cfg.memory != null) {
          ".claude/CLAUDE.md".text = cfg.memory;
        }
        ++ lib.mapAttrsToList (name: src: {
          ".claude/skills/${name}" = {
            source = src;
            recursive = true;
          };
        })
        cfg.skills
      );

      myHomeModules.persistence = {
        directories = [".claude"];
        files = [".claude.json"];
      };
    };
  };
}
