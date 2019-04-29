import ./make-test.nix {
  name = "prometheus-2";

  nodes = {
    one = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.jq ];
      services.prometheus2 = {
        enable = true;
        scrapeConfigs = [
          {
            job_name = "prometheus";
            static_configs = [
              {
                targets = [ "127.0.0.1:9090" ];
                labels = { instance = "localhost"; };
              }
            ];
          }
          {
            job_name = "pushgateway";
            scrape_interval = "1s";
            static_configs = [
              {
                targets = [ "127.0.0.1:9091" ];
              }
            ];
          }
        ];
        rules = [
          ''
            groups:
              - name: test
                rules:
                  - record: testrule
                    expr: count(up{job="prometheus"})
          ''
        ];
        globalConfig = {
          external_labels = {
            some_label = "required by thanos";
          };
        };
        extraFlags = [
          # Required by thanos
          "--storage.tsdb.min-block-duration=2h"
          "--storage.tsdb.max-block-duration=2h"
        ];
      };
      services.prometheus.pushgateway = {
        enable = true;
        persistMetrics = true;
        persistence.interval = "1s";
        stateDir = "prometheus-pushgateway";
      };
      services.thanos = {
        sidecar = {
          enable = true;
          #objstore.config = {
          #  type = "S3";
          #  config = {
          #    bucket = "foo-bucket";
          #    endpoint = "foo-endpoit";
          #    region = "eu-central-1";
          #    access_key = "sdfsdfsdfsdf";
          #    insecure = false;
          #    signature_version2 = false;
          #    encrypt_sse = false;
          #    secret_key = "dssdfsdfsdfsdfsdf";
          #    put_user_metadata = {};
          #    http_config = {
          #      idle_conn_timeout = "0s";
          #      insecure_skip_verify = false;
          #    };
          #    trace = {
          #      enable = false;
          #    };
          #  };
          #};
        };
        query = {
          enable = true;
          http-address = "0.0.0.0:19192";
          grpc-address = "0.0.0.0:19191";
          store.addresses = [
            "localhost:19090"
          ];
        };
        rule = {
          enable = true;
          http-address = "0.0.0.0:19194";
          grpc-address = "0.0.0.0:19193";
          query.addresses = [
            "localhost:19192"
          ];
          labels = {
            just = "some";
            nice = "labels";
          };
        };
        receive = {
          http-address = "0.0.0.0:19195";
          enable = true;
          labels = {
            just = "some";
            nice = "labels";
          };
        };
      };
    };
  };

  testScript = ''
    startAll;
    $one->waitForUnit("prometheus2.service");
    $one->waitForOpenPort(9090);
    $one->succeed("curl -s http://127.0.0.1:9090/metrics");

    # Let's test if pushing a metric to the pushgateway succeeds
    # and whether that metric gets ingested by prometheus.
    $one->waitForUnit("pushgateway.service");
    $one->succeed(
      "echo 'some_metric 3.14' | " .
      "curl --data-binary \@- http://127.0.0.1:9091/metrics/job/some_job");
    $one->waitUntilSucceeds(
      "curl -sf 'http://127.0.0.1:9090/api/v1/query?query=some_metric' " .
      "| jq '.data.result[0].value[1]' | grep '\"3.14\"'");

    # Let's test if the pushgateway persists metrics to the configured location.
    $one->waitUntilSucceeds("test -e /var/lib/prometheus-pushgateway/metrics");

    # Test thanos
    $one->waitForUnit("thanos-sidecar.service");
    $one->waitForUnit("thanos-query.service");
    $one->waitForUnit("thanos-rule.service");
    $one->waitForUnit("thanos-receive.service");
  '';
}
