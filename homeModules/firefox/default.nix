{
  inputs,
  pkgs,
  pkgs-stable,
  lib,
  config,
  system,
  ...
}: let
  cfg = config.myHomeModules.firefox;

  profile = "dev-edition-default";
in {
  options.myHomeModules.firefox = {
    enable =
      lib.mkEnableOption "enables firefox"
      // {
        default = false;
      };
  };
  config = lib.mkIf cfg.enable {
    programs.firefox = {
      enable = true;
      # package = pkgs.firefox-devedition;
      package = pkgs-stable.firefox-devedition;
      profiles = {
        "${profile}" = {
          isDefault = true;
          settings = {
            "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
            "ui.systemUsesDarkTheme" = 1;
            "privacy.userContext.enabled" = true;
            "privacy.userContext.extension" = "@contain-facebook";
            "privacy.userContext.newTabContainerOnLeftClick.enabled" = true;
            "privacy.userContext.ui.enabled" = true;
            "ui.key.menuAccessKeyFocuses" = false;
            "app.normandy.api_url" = "";
            "app.normandy.enabled" = false;
            "app.shield.optoutstudies.enabled" = false;
            "app.update.auto" = false;
            "beacon.enabled" = false;
            "breakpad.reportURL" = "";
            "browser.aboutConfig.showWarning" = false;
            "browser.cache.offline.enable" = false;
            "browser.crashReports.unsubmittedCheck.autoSubmit" = false;
            "browser.crashReports.unsubmittedCheck.autoSubmit2" = false;
            "browser.crashReports.unsubmittedCheck.enabled" = false;
            "browser.disableResetPrompt" = true;
            "browser.newtab.preload" = false;
            "browser.newtabpage.activity-stream.section.highlights.includePocket" = false;
            "browser.newtabpage.enhanced" = false;
            "browser.newtabpage.introShown" = true;
            "browser.safebrowsing.appRepURL" = "";
            "browser.safebrowsing.blockedURIs.enabled" = false;
            "browser.safebrowsing.downloads.enabled" = false;
            "browser.safebrowsing.downloads.remote.enabled" = false;
            "browser.safebrowsing.downloads.remote.url" = "";
            "browser.safebrowsing.enabled" = false;
            "browser.safebrowsing.malware.enabled" = false;
            "browser.safebrowsing.phishing.enabled" = false;
            "browser.selfsupport.url" = "";
            "browser.send_pings" = false;
            "browser.sessionstore.privacy_level" = 0;
            "browser.shell.checkDefaultBrowser" = false;
            "browser.startup.homepage_override.mstone" = "ignore";
            "browser.tabs.crashReporting.sendReport" = false;
            # disable "titlebar-buttonbox"
            "browser.tabs.inTitlebar" = 0;
            "browser.urlbar.groupLabels.enabled" = false;
            "browser.urlbar.quicksuggest.enabled" = false;
            "browser.urlbar.speculativeConnect.enabled" = false;
            "browser.urlbar.trimURLs" = false;
            "datareporting.healthreport.service.enabled" = false;
            "datareporting.healthreport.uploadEnabled" = false;
            "datareporting.policy.dataSubmissionEnabled" = false;
            "device.sensors.ambientLight.enabled" = false;
            "device.sensors.enabled" = false;
            "device.sensors.motion.enabled" = false;
            "device.sensors.orientation.enabled" = false;
            "device.sensors.proximity.enabled" = false;
            "dom.battery.enabled" = false;
            "dom.event.clipboardevents.enabled" = true;
            "dom.webaudio.enabled" = false;
            "experiments.activeExperiment" = false;
            "experiments.enabled" = false;
            "experiments.manifest.uri" = "";
            "experiments.supported" = false;
            "extensions.getAddons.cache.enabled" = false;
            "extensions.getAddons.showPane" = false;
            "extensions.pocket.enabled" = false;
            "extensions.shield-recipe-client.api_url" = "";
            "extensions.shield-recipe-client.enabled" = false;
            "extensions.webservice.discoverURL" = "";
            "extensions.autoDisableScopes" = 0;
            "media.autoplay.default" = 0;
            "media.autoplay.enabled" = true;
            "media.eme.enabled" = false;
            "media.gmp-widevinecdm.enabled" = false;
            "media.navigator.enabled" = false;
            "media.peerconnection.enabled" = false;
            "media.video_stats.enabled" = false;
            "network.allow-experiments" = false;
            "network.captive-portal-service.enabled" = false;
            "network.cookie.cookieBehavior" = 1;
            "network.dns.disablePrefetch" = true;
            "network.dns.disablePrefetchFromHTTPS" = true;
            "network.http.referer.spoofSource" = true;
            "network.http.speculative-parallel-limit" = 0;
            "network.predictor.enable-prefetch" = false;
            "network.predictor.enabled" = false;
            "network.prefetch-next" = false;
            "network.trr.mode" = 5;
            "privacy.donottrackheader.enabled" = true;
            "privacy.donottrackheader.value" = 1;
            "privacy.query_stripping" = true;
            "privacy.trackingprotection.cryptomining.enabled" = true;
            "privacy.trackingprotection.enabled" = true;
            "privacy.trackingprotection.fingerprinting.enabled" = true;
            "privacy.trackingprotection.pbmode.enabled" = true;
            "privacy.usercontext.about_newtab_segregation.enabled" = true;
            "security.ssl.disable_session_identifiers" = true;
            "services.sync.prefs.sync.browser.newtabpage.activity-stream.showSponsoredTopSite" = false;
            "signon.autofillForms" = false;
            "toolkit.telemetry.archive.enabled" = false;
            "toolkit.telemetry.bhrPing.enabled" = false;
            "toolkit.telemetry.cachedClientID" = "";
            "toolkit.telemetry.enabled" = false;
            "toolkit.telemetry.firstShutdownPing.enabled" = false;
            "toolkit.telemetry.hybridContent.enabled" = false;
            "toolkit.telemetry.newProfilePing.enabled" = false;
            "toolkit.telemetry.prompted" = 2;
            "toolkit.telemetry.rejected" = true;
            "toolkit.telemetry.reportingpolicy.firstRun" = false;
            "toolkit.telemetry.server" = "";
            "toolkit.telemetry.shutdownPingSender.enabled" = false;
            "toolkit.telemetry.unified" = false;
            "toolkit.telemetry.unifiedIsOptIn" = false;
            "toolkit.telemetry.updatePing.enabled" = false;
            "webgl.disabled" = false;
            "webgl.renderer-string-override" = " ";
            "webgl.vendor-string-override" = " ";
          };
          search = {
            default = "DuckDuckGo";

            engines = {
              "Nix Packages" = {
                urls = [
                  {
                    template = "https://search.nixos.org/packages";
                    params = [
                      {
                        name = "type";
                        value = "packages";
                      }
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                definedAliases = ["@np"];
              };
              "Pursuit" = {
                urls = [
                  {
                    template = "https://pursuit.purescript.org/search";
                    params = [
                      {
                        name = "q";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
                definedAliases = ["@pp"];
              };
              "Rust Std" = {
                urls = [
                  {
                    template = "https://doc.rust-lang.org/std/";
                    params = [
                      {
                        name = "search";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
                definedAliases = ["@rs"];
              };
              "Hoogle" = {
                urls = [
                  {
                    template = "https://hoogle.haskell.org/";
                    params = [
                      {
                        name = "hoogle";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
                definedAliases = ["@ho"];
              };
            };

            force = true;
          };

          containers = {
            Personal = {
              color = "blue";
              icon = "tree";
              id = 1;
            };
            Work-1 = {
              color = "orange";
              icon = "briefcase";
              id = 2;
            };
            Work-2 = {
              color = "purple";
              icon = "briefcase";
              id = 3;
            };
          };
          containersForce = true;

          extensions.packages = with inputs.firefox-addons.packages.${system}; [
            bitwarden
            ublock-origin
            decentraleyes
            sponsorblock
            darkreader
            tridactyl
            react-devtools
            reduxdevtools
            facebook-container
          ];
        };
      };
    };
  };
}
