{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.thanos;

  cmdArgs = rec {
    log = cmd :
         opt  "log.level"                           cmd.log.level
      ++ opt  "log.format"                          cmd.log.format;

    gcloudtrace = cmd :
         opt  "gcloudtrace.project"                 cmd.gcloudtrace.project
      ++ opt  "gcloudtrace.sample-factor"           cmd.gcloudtrace.sample-factor;

    objstore = cmd :
         opt  "objstore.config-file" (toObjStoreCfg cmd.objstore.config);

    common = cmd :
         log                                        cmd
      ++ gcloudtrace                                cmd
      ++ opt  "http-address"                        cmd.http-address
      ++ opt  "grpc-address"                        cmd.grpc-address
      ++ opt  "grpc-server-tls-cert"                cmd.grpc-server-tls-cert
      ++ opt  "grpc-server-tls-key"                 cmd.grpc-server-tls-key
      ++ opt  "grpc-server-tls-client-ca"           cmd.grpc-server-tls-client-ca;

    sidecar =
         common                                     cfg.sidecar
      ++ opt  "prometheus.url"                      cfg.sidecar.prometheus.url
      ++ opt  "tsdb.path"                           cfg.sidecar.tsdb.path
      ++ opt  "reloader.config-file"                cfg.sidecar.reloader.config-file
      ++ opt  "reloader.config-envsubst-file"       cfg.sidecar.reloader.config-envsubst-file
      ++ list "reloader.rule-dir"                   cfg.sidecar.reloader.rule-dirs
      ++ objstore                                   cfg.sidecar;

    store =
         common                                     cfg.store
      ++ opt   "data-dir"            ("/var/lib/" + cfg.store.stateDir)
      ++ opt   "index-cache-size"                   cfg.store.index-cache-size
      ++ opt   "chunk-pool-size"                    cfg.store.chunk-pool-size
      ++ opt   "store.grpc.series-sample-limit"     cfg.store.store.grpc.series-sample-limit
      ++ opt   "store.grpc.series-max-concurrency"  cfg.store.store.grpc.series-max-concurrency
      ++ objstore                                   cfg.store
      ++ opt   "sync-block-duration"                cfg.store.sync-block-duration
      ++ opt   "block-sync-concurrency"             cfg.store.block-sync-concurrency;

    query =
         common                                     cfg.query
      ++ opt   "http-advertise-address"             cfg.query.http-advertise-address
      ++ flag  "grpc-client-tls-secure"             cfg.query.grpc-client-tls-secure
      ++ opt   "grpc-client-tls-cert"               cfg.query.grpc-client-tls-cert
      ++ opt   "grpc-client-tls-key"                cfg.query.grpc-client-tls-key
      ++ opt   "grpc-client-tls-ca"                 cfg.query.grpc-client-tls-ca
      ++ opt   "grpc-client-server-name"            cfg.query.grpc-client-server-name
      ++ opt   "web.route-prefix"                   cfg.query.web.route-prefix
      ++ opt   "web.external-prefix"                cfg.query.web.external-prefix
      ++ opt   "web.prefix-header"                  cfg.query.web.prefix-header
      ++ opt   "query.timeout"                      cfg.query.query.timeout
      ++ opt   "query.max-concurrent"               cfg.query.query.max-concurrent
      ++ opt   "query.replica-label"                cfg.query.query.replica-label
      ++ attrs "selector-label"                     cfg.query.selector-labels
      ++ list  "store"                              cfg.query.store.addresses
      ++ list  "store.sd-files"                     cfg.query.store.sd-files
      ++ opt   "store.sd-interval"                  cfg.query.store.sd-interval
      ++ opt   "store.sd-dns-interval"              cfg.query.store.sd-dns-interval
      ++ opt   "store.unhealthy-timeout"            cfg.query.store.unhealthy-timeout
      ++ flag  "query.auto-downsampling"            cfg.query.query.auto-downsampling
      ++ flag  "query.partial-response"             cfg.query.query.partial-response
      ++ opt   "query.default-evaluation-interval"  cfg.query.query.default-evaluation-interval
      ++ opt   "store.response-timeout"             cfg.query.store.response-timeout;

    rule =
         common                                     cfg.rule
      ++ attrs "label"                              cfg.rule.labels
      ++ opt   "data-dir"            ("/var/lib/" + cfg.rule.stateDir)
      ++ list  "rule-file"                          cfg.rule.rule-files
      ++ opt   "eval-interval"                      cfg.rule.eval-interval
      ++ opt   "tsdb.block-duration"                cfg.rule.tsdb.block-duration
      ++ opt   "tsdb.retention"                     cfg.rule.tsdb.retention
      ++ list  "alertmanagers.url"                  cfg.rule.alertmanagers.urls
      ++ opt   "alertmanagers.send-timeout"         cfg.rule.alertmanagers.send-timeout
      ++ opt   "alert.query-url"                    cfg.rule.alert.query-url
      ++ list  "alert.label-drop"                   cfg.rule.alert.label-drop
      ++ opt   "web.route-prefix"                   cfg.rule.web.route-prefix
      ++ opt   "web.external-prefix"                cfg.rule.web.external-prefix
      ++ opt   "web.prefix-header"                  cfg.rule.web.prefix-header
      ++ objstore                                   cfg.rule
      ++ list  "query"                              cfg.rule.query.addresses
      ++ list  "query.sd-files"                     cfg.rule.query.sd-files
      ++ opt   "query.sd-interval"                  cfg.rule.query.sd-interval
      ++ opt   "query.sd-dns-interval"              cfg.rule.query.sd-dns-interval;

    compact =
         log                                        cfg.compact
      ++ gcloudtrace                                cfg.compact
      ++ opt   "http-address"                       cfg.compact.http-address
      ++ opt   "data-dir"            ("/var/lib/" + cfg.compact.stateDir)
      ++ objstore                                   cfg.compact
      ++ opt   "sync-delay"                         cfg.compact.sync-delay
      ++ opt   "retention.resolution-raw"           cfg.compact.retention.resolution-raw
      ++ opt   "retention.resolution-5m"            cfg.compact.retention.resolution-5m
      ++ opt   "retention.resolution-1h"            cfg.compact.retention.resolution-1h
      ++ flag  "wait"                              (cfg.compact.startAt == null)
      ++ opt   "block-sync-concurrency"             cfg.compact.block-sync-concurrency
      ++ opt   "compact.concurrency"                cfg.compact.compact.concurrency;

    downsample =
         log                                        cfg.downsample
      ++ gcloudtrace                                cfg.downsample
      ++ opt   "data-dir"            ("/var/lib/" + cfg.downsample.stateDir)
      ++ objstore                                   cfg.downsample;

    receive =
         common                                     cfg.receive
      ++ opt   "remote-write.address"               cfg.receive.remote-write.address
      ++ opt   "tsdb.path"           ("/var/lib/" + cfg.receive.stateDir)
      ++ attrs "labels"                             cfg.receive.labels
      ++ objstore                                   cfg.receive
      ++ opt   "tsdb.retention"                     cfg.receive.tsdb.retention;

  };

  opt   = o :  v  : optional (v != null)  ''--${o}="${v}"'';
  flag  = o :  v  : optional  v           ''--${o}'';
  attrs = o : kvs : mapAttrsToList (k: v: ''--${o}=${k}=\"${v}\"'') kvs;
  list  = o :  vs : map            (v:    ''--${o}="${v}"'') vs;

  toObjStoreCfg = attrs : if attrs == null then null else
    pkgs.runCommandNoCC "objstore.yaml" {
      preferLocalBuild = true;
      json = builtins.toFile "objstore.json" (builtins.toJSON attrs);
    } ''${pkgs.remarshal}/bin/json2yaml -i $json -o $out'';

  thanos = cmd : args : "${cfg.package}/bin/thanos ${cmd}" +
    optionalString (length args != 0) (" \\\n  " +
      concatStringsSep " \\\n  " args);

  mkDefOpt = type : defaultStr : description : mkOpt type (description + ''

    Defaults to <literal>${defaultStr}</literal> in thanos
    when set to <literal>null</literal>.
  '');

  mkOpt = type : description : mkOption {
    type = types.nullOr type;
    default = null;
    inherit description;
  };

  options = {

    log = {

      log.level = mkDefOpt (types.enum ["debug" "info" "warn" "error" "fatal"]) "info" ''
        Log filtering level.
      '';

      log.format = mkOpt types.str ''
        Log format to use.
      '';
    };

    gcloudtrace = {

      gcloudtrace.project = mkOpt types.str ''
        GCP project to send Google Cloud Trace tracings to.

        If empty, tracing will be disabled.
      '';

      gcloudtrace.sample-factor = mkDefOpt types.int "1" ''
        How often we send traces <literal>1/&lt;sample-factor&gt;</literal>.

        If 0 no trace will be sent periodically, unless forced by baggage item.
      '';
    };

    common = options.log // options.gcloudtrace // {

      http-address = mkDefOpt types.str "0.0.0.0:10902" ''
        Listen host:port for HTTP endpoints.
      '';

      grpc-address = mkDefOpt types.str "0.0.0.0:10901" ''
        Listen <literal>ip:port</literal> address for gRPC endpoints (StoreAPI).

        Make sure this address is routable from other components if you use gossip,
        <option>grpc-advertise-address</option> is empty and you require cross-node connection.
      '';

      grpc-server-tls-cert = mkOpt types.str ''
        TLS Certificate for gRPC server, leave blank to disable TLS
      '';

      grpc-server-tls-key = mkOpt types.str ''
        TLS Key for the gRPC server, leave blank to disable TLS
      '';

      grpc-server-tls-client-ca = mkOpt types.str ''
        TLS CA to verify clients against.

        If no client CA is specified, there is no client verification on server side.
        (tls.NoClientCert)
      '';
    };

    objstore = {

      objstore.config = mkOpt types.attrs ''
        Object store configuration.

        (This Nix attribute set will get converted to YAML).
      '';
    };
  };
in {

  options.services.thanos = {

    package = mkOption {
      type = types.package;
      default = pkgs.thanos;
      defaultText = "pkgs.thanos";
      description = ''
        The thanos package that should be used.
      '';
    };

    sidecar = options.common // options.objstore // {

      enable = mkEnableOption "Thanos sidecar for Prometheus server";

      prometheus.url = mkDefOpt types.str "http://localhost:9090" ''
        URL at which to reach Prometheus's API.

        For better performance use local network.
      '';

      tsdb.path = mkOption {
        type = types.str;
        default = "/var/lib/${config.services.prometheus2.stateDir}/data";
        defaultText = "/var/lib/\${config.services.prometheus2.stateDir}/data";
        description = ''
          Data directory of TSDB.
        '';
      };

      reloader.config-file = mkOpt types.str ''
        Config file watched by the reloader.
      '';

      reloader.config-envsubst-file = mkOpt types.str ''
        Output file for environment variable substituted config file.
      '';

      reloader.rule-dirs = mkOption {
        type = types.listOf types.str;
        default = [];
        description = ''
          Rule directories for the reloader to refresh.
        '';
      };
    };

    store = options.common // options.objstore // {

      enable = mkEnableOption "Thanos store node giving access to blocks in a bucket provider.";

      stateDir = mkOption {
        type = types.str;
        default = "thanos-store";
        description = ''
          Data directory relative to <literal>/var/lib</literal>
          in which to cache remote blocks.
        '';
      };

      index-cache-size = mkDefOpt types.str "250MB" ''
        Maximum size of items held in the index cache.
      '';

      chunk-pool-size = mkDefOpt types.str "2GB" ''
        Maximum size of concurrently allocatable bytes for chunks.
      '';

      store.grpc.series-sample-limit = mkDefOpt types.int "0" ''
        Maximum amount of samples returned via a single Series call. 0 means
        no limit. NOTE: for efficiency we take 120 as the number of samples in
        chunk (it cannot be bigger than that), so the actual number of samples
        might be lower, even though the maximum could be hit.
      '';

      store.grpc.series-max-concurrency = mkDefOpt types.int "20" ''
        Maximum number of concurrent Series calls.
      '';

      sync-block-duration = mkDefOpt types.str "3m" ''
        Repeat interval for syncing the blocks between local and remote view.
      '';

      block-sync-concurrency = mkDefOpt types.int "20" ''
        Number of goroutines to use when syncing blocks from object storage.
      '';
    };

    query = options.common // {

      enable = mkEnableOption
        ("Thanos query node exposing PromQL enabled Query API " +
         "with data retrieved from multiple store nodes");

      http-advertise-address = mkOpt types.str ''
        Explicit (external) host:port address to advertise for HTTP QueryAPI
        in gossip cluster. If empty, 'http-address' will be used.
      '';

      grpc-client-tls-secure = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Use TLS when talking to the gRPC server
        '';
      };

      grpc-client-tls-cert = mkOpt types.str ''
        TLS Certificates to use to identify this client to the server
      '';

      grpc-client-tls-key = mkOpt types.str ''
        TLS Key for the client's certificate
      '';

      grpc-client-tls-ca = mkOpt types.str ''
        TLS CA Certificates to use to verify gRPC servers
      '';

      grpc-client-server-name = mkOpt types.str ''
        Server name to verify the hostname on the returned gRPC certificates.
        See https://tools.ietf.org/html/rfc4366#section-3.1
      '';

      web.route-prefix = mkOpt types.str ''
        Prefix for API and UI endpoints. This allows thanos UI to be served on
        a sub-path. This option is analogous to --web.route-prefix of
        Promethus.
      '';

      web.external-prefix = mkOpt types.str ''
        Static prefix for all HTML links and redirect URLs in the UI query web
        interface. Actual endpoints are still served on / or the
        web.route-prefix. This allows thanos UI to be served behind a reverse
        proxy that strips a URL sub-path.
      '';

      web.prefix-header = mkOpt types.str ''
        Name of HTTP request header used for dynamic prefixing of UI links and
        redirects. This option is ignored if web.external-prefix argument is
        set. Security risk: enable this option only if a reverse proxy in
        front of thanos is resetting the header. The
        --web.prefix-header=X-Forwarded-Prefix option can be useful, for
        example, if Thanos UI is served via Traefik reverse proxy with
        PathPrefixStrip option enabled, which sends the stripped prefix value
        in X-Forwarded-Prefix header. This allows thanos UI to be served on a
        sub-path.
      '';

      query.timeout = mkDefOpt types.str "2m" ''
        Maximum time to process query by query node.
      '';

      query.max-concurrent = mkDefOpt types.int "20" ''
        Maximum number of queries processed concurrently by query node.
      '';

      query.replica-label = mkOpt types.str ''
        Label to treat as a replica indicator along which data is
        deduplicated. Still you will be able to query without deduplication
        using 'dedup=false' parameter.
      '';

      selector-labels = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = ''
          Query selector labels that will be exposed in info endpoint.
        '';
      };

      store.addresses = mkOption {
        type = types.listOf types.str;
        default = [];
        description = ''
          Addresses of statically configured store API servers (repeatable). The
          scheme may be prefixed with 'dns+' or 'dnssrv+' to detect store API
          servers through respective DNS lookups.
        '';
      };

      store.sd-files = mkOption {
        type = types.listOf types.str;
        default = [];
        description = ''
          Path to files that contain addresses of store API servers. The path
          can be a glob pattern.
        '';
      };

      store.sd-interval = mkDefOpt types.str "5m" ''
        Refresh interval to re-read file SD files. It is used as a resync fallback.
      '';

      store.sd-dns-interval = mkDefOpt types.str "30s" ''
        Interval between DNS resolutions.
      '';

      store.unhealthy-timeout = mkDefOpt types.str "5m" ''
        Timeout before an unhealthy store is cleaned from the store UI page.
      '';

      query.auto-downsampling = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable automatic adjustment (step / 5) to what source of data should
          be used in store gateways if no max_source_resolution param is
          specified.
        '';
      };

      query.partial-response = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable partial response for queries if no partial_response param is specified.
        '';
      };

      query.default-evaluation-interval = mkDefOpt types.str "1m" ''
        Set default evaluation interval for sub queries.
      '';

      store.response-timeout = mkDefOpt types.str "0ms" ''
        If a Store doesn't send any data in this specified duration then a
        Store will be ignored and partial data will be returned if it's
        enabled. 0 disables timeout.
      '';
    };

    rule = options.common // options.objstore // {

      enable = mkEnableOption
        ("Thanos ruler evaluating Prometheus rules against given Query nodes, " +
         "exposing Store API and storing old blocks in bucket");

      labels = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = ''
          Labels to be applied to all generated metrics.

          Similar to external labels for Prometheus,
          used to identify ruler and its blocks as unique source.
        '';
      };

      stateDir = mkOption {
        type = types.str;
        default = "thanos-rule";
        description = ''
          Data directory relative to <literal>/var/lib</literal>.
        '';
      };

      rule-files = mkOption {
        type = types.listOf types.str;
        default = [];
        description = ''
          Rule files that should be used by rule manager. Can be in glob format.
        '';
      };

      eval-interval = mkDefOpt types.str "30s" ''
        The default evaluation interval to use.
      '';

      tsdb.block-duration = mkDefOpt types.str "2h" ''
        Block duration for TSDB block.
      '';

      tsdb.retention = mkDefOpt types.str "48h" ''
        Block retention time on local disk.
      '';

      alertmanagers.urls = mkOption {
        type = types.listOf types.str;
        default = [];
        description = ''
          Alertmanager replica URLs to push firing alerts. Ruler claims success
          if push to at least one alertmanager from discovered succeeds. The
          scheme may be prefixed with <literal>dns+</literal> or
          <literal>dnssrv+</literal> to detect Alertmanager IPs through
          respective DNS lookups.  The port defaults to 9093 or the SRV record's
          value. The URL path is used as a prefix for the regular Alertmanager
          API path.
        '';
      };

      alertmanagers.send-timeout = mkDefOpt types.str "10s" ''
        Timeout for sending alerts to alertmanager.
      '';

      alert.query-url = mkOpt types.str ''
        The external Thanos Query URL that would be set in all alerts 'Source' field.
      '';

      alert.label-drop = mkOption {
        type = types.listOf types.str;
        default = [];
        description = ''
          Labels by name to drop before sending to alertmanager.

          This allows alert to be deduplicated on replica label.

          Similar Prometheus alert relabelling
        '';
      };

      web.route-prefix = mkOpt types.str ''
        Prefix for API and UI endpoints.

        This allows thanos UI to be served on a sub-path.

        This option is analogous to <literal>--web.route-prefix</literal> of Promethus.
      '';

      web.external-prefix = mkOpt types.str ''
        Static prefix for all HTML links and redirect URLs in the UI query web
        interface. Actual endpoints are still served on / or the
        web.route-prefix. This allows thanos UI to be served behind a reverse
        proxy that strips a URL sub-path.
      '';

      web.prefix-header = mkOpt types.str ''
        Name of HTTP request header used for dynamic prefixing of UI links and
        redirects. This option is ignored if web.external-prefix argument is
        set. Security risk: enable this option only if a reverse proxy in front
        of thanos is resetting the header. The header
        <literal>X-Forwarded-Prefix</literal> can be useful, for example, if
        Thanos UI is served via Traefik reverse proxy with
        <literal>PathPrefixStrip</literal> option enabled, which sends the
        stripped prefix value in <literal>X-Forwarded-Prefix</literal>
        header. This allows thanos UI to be served on a sub-path.
      '';

      query.addresses = mkOption {
        type = types.listOf types.str;
        default = [];
        description = ''
          Addresses of statically configured query API servers.

          The scheme may be prefixed with <literal>dns+</literal> or
          <literal>dnssrv+</literal> to detect query API servers through
          respective DNS lookups.
        '';
      };

      query.sd-files = mkOption {
        type = types.listOf types.str;
        default = [];
        description = ''
          Path to file that contain addresses of query peers. The path can be a glob pattern.
        '';
      };

      query.sd-interval = mkDefOpt types.str "5m" ''
        Refresh interval to re-read file SD files. (used as a fallback)
      '';

      query.sd-dns-interval = mkDefOpt types.str "30s" ''
        Interval between DNS resolutions.
      '';
    };

    compact = options.log // options.gcloudtrace // options.objstore // {

      enable = mkEnableOption
        "Thanos compactor which continuously compacts blocks in an object store bucket";

      startAt = mkOpt types.str ''
        When this option is set to a <literal>systemd.time</literal>
        specification the Thanos compactor will run at the specified period.

        When this options is <literal>null</literal> the Thanos compactor
        service will not exit after all compactions have been processed and wait
        for new work.
      '';

      http-address = mkDefOpt types.str "0.0.0.0:10902" ''
        Listen host:port for HTTP endpoints.
      '';

      stateDir = mkOption {
        type = types.str;
        default = "thanos-compact";
        description = ''
          Data directory relative to <literal>/var/lib</literal>
          in which to cache blocks and process compactions.
        '';
      };

      sync-delay = mkDefOpt types.str "30m" ''
        Minimum age of fresh (non-compacted) blocks before they are being processed.
      '';

      retention.resolution-raw = mkDefOpt types.str "0d" ''
        How long to retain raw samples in bucket.

        0d - disables this retention
      '';

      retention.resolution-5m = mkDefOpt types.str "0d" ''
        How long to retain samples of resolution 1 (5 minutes) in bucket.

        0d - disables this retention
      '';

      retention.resolution-1h = mkDefOpt types.str "0d" ''
        How long to retain samples of resolution 2 (1 hour) in bucket.

        0d - disables this retention
      '';

      block-sync-concurrency = mkDefOpt types.str "20" ''
        Number of goroutines to use when syncing block metadata from object storage.
      '';

      compact.concurrency = mkDefOpt types.str "1" ''
        Number of goroutines to use when compacting groups.
      '';
    };

    downsample = options.log // options.gcloudtrace // options.objstore // {

      enable = mkEnableOption
        "Thanos downsampler which continuously downsamples blocks in an object store bucket";

      stateDir = mkOption {
        type = types.str;
        default = "thanos-downsample";
        description = ''
          Data directory relative to <literal>/var/lib</literal>
          in which to cache blocks and process downsamplings.
        '';
      };
    };

    receive = options.common // options.objstore // {

      enable = mkEnableOption
        ("Thanos receiver which accept Prometheus remote write API requests " +
         "and write to local tsdb (EXPERIMENTAL, this may change drastically without notice)");

      remote-write.address = mkDefOpt types.str "0.0.0.0:19291" ''
        Address to listen on for remote write requests.
      '';

      stateDir = mkOption {
        type = types.str;
        default = "thanos-receive";
        description = ''
          Data directory relative to <literal>/var/lib</literal> of TSDB.
        '';
      };

      labels = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = ''
          External labels to announce.

          This flag will be removed in the future when handling multiple tsdb
          instances is added.
        '';
      };

      tsdb.retention = mkDefOpt types.str "15d" ''
        How long to retain raw samples on local storage.

        0d - disables this retention
      '';
    };
  };

  config = mkMerge [

    (mkIf cfg.sidecar.enable {
      systemd.services.thanos-sidecar = {
        wantedBy = [ "multi-user.target" ];
        after    = [ "network.target" "prometheus2.service" ];
        serviceConfig = {
          User = "prometheus";
          Restart = "always";
          ExecStart = thanos "sidecar" cmdArgs.sidecar;
        };
      };
    })

    (mkIf cfg.store.enable {
      assertions = [
        {
          assertion = !hasPrefix "/" cfg.store.stateDir;
          message =
            "The option services.thanos.store.stateDir" +
            " shouldn't be an absolute directory." +
            " It should be a directory relative to /var/lib.";
        }
      ];
      systemd.services.thanos-store = {
        wantedBy = [ "multi-user.target" ];
        after    = [ "network.target" ];
        serviceConfig = {
          DynamicUser = true;
          StateDirectory = cfg.store.stateDir;
          Restart = "always";
          ExecStart = thanos "store" cmdArgs.store;
        };
      };
    })

    (mkIf cfg.query.enable {
      systemd.services.thanos-query = {
        wantedBy = [ "multi-user.target" ];
        after    = [ "network.target" ];
        serviceConfig = {
          DynamicUser = true;
          Restart = "always";
          ExecStart = thanos "query" cmdArgs.query;
        };
      };
    })

    (mkIf cfg.rule.enable {
      assertions = [
        {
          assertion = !hasPrefix "/" cfg.rule.stateDir;
          message =
            "The option services.thanos.rule.stateDir" +
            " shouldn't be an absolute directory." +
            " It should be a directory relative to /var/lib.";
        }
      ];
      systemd.services.thanos-rule = {
        wantedBy = [ "multi-user.target" ];
        after    = [ "network.target" ];
        serviceConfig = {
          DynamicUser = true;
          StateDirectory = cfg.rule.stateDir;
          Restart = "always";
          ExecStart = thanos "rule" cmdArgs.rule;
        };
      };
    })

    (mkIf cfg.compact.enable {
      assertions = [
        {
          assertion = !hasPrefix "/" cfg.compact.stateDir;
          message =
            "The option services.thanos.compact.stateDir" +
            " shouldn't be an absolute directory." +
            " It should be a directory relative to /var/lib.";
        }
      ];
      systemd.services.thanos-compact = let wait = cfg.compact.startAt == null; in {
        wantedBy = [ "multi-user.target" ];
        after    = [ "network.target" ];
        serviceConfig = {
          Type    = if wait then "simple" else "oneshot";
          Restart = if wait then "always" else "no";
          DynamicUser = true;
          StateDirectory = cfg.compact.stateDir;
          ExecStart = thanos "compact" cmdArgs.compact;
        } // optionalAttrs (!wait) { inherit (cfg.compact) startAt; };
      };
    })

    (mkIf cfg.downsample.enable {
      assertions = [
        {
          assertion = !hasPrefix "/" cfg.downsample.stateDir;
          message =
            "The option services.thanos.downsample.stateDir" +
            " shouldn't be an absolute directory." +
            " It should be a directory relative to /var/lib.";
        }
      ];
      systemd.services.thanos-downsample = {
        wantedBy = [ "multi-user.target" ];
        after    = [ "network.target" ];
        serviceConfig = {
          DynamicUser = true;
          StateDirectory = cfg.downsample.stateDir;
          Restart = "always";
          ExecStart = thanos "downsample" cmdArgs.downsample;
        };
      };
    })

    (mkIf cfg.receive.enable {
      assertions = [
        {
          assertion = !hasPrefix "/" cfg.receive.stateDir;
          message =
            "The option services.thanos.receive.stateDir" +
            " shouldn't be an absolute directory." +
            " It should be a directory relative to /var/lib.";
        }
      ];
      systemd.services.thanos-receive = {
        wantedBy = [ "multi-user.target" ];
        after    = [ "network.target" ];
        serviceConfig = {
          DynamicUser = true;
          StateDirectory = cfg.receive.stateDir;
          Restart = "always";
          ExecStart = thanos "receive" cmdArgs.receive;
        };
      };
    })

  ];
}
