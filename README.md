# xmrig-proxy.cmd
Windows Batch Script for automated start XMRig Proxy (https://github.com/xmrig/xmrig-proxy) with parameters. Can run various proxy instances (pre-saved proxy configurations by addresses, ports, etc.), based on the configuration of pools, algorithms that are used for a particular coin, automatically substituting the required values into the program command line (collecting several pools at the time of the failure list)

Run with available parameters: "xmrig-proxy.cmd --proxy=<proxy_name> --coin=<coin_name> --elevate=<true/false>", where "<proxy_name>" is name in configuration file and "<coin_name>" too.
If you run it without any params (and "ALLOW_MANUAL_SELECT" set to "true") you can manually select what ever you want to run.

Don't forget to change a configuration file.
![xmrig-proxy.cmd](https://github.com/equuleus/screenshots/blob/master/xmrig-proxy.cmd.png "xmrig-proxy.cmd")
