# xmrig-proxy.cmd
Windows Batch Script for automated start XMRig Proxy (https://github.com/xmrig/xmrig-proxy) with parameters. Can run various proxy instances (pre-saved proxy configurations by addresses, ports, parameters, etc.), based on the configuration of pools, algorithms, wallets that are used for a particular coin, automatically substituting the required values into the program command line (collecting several pools at the time of the failure list).

Run with available parameters: "xmrig-proxy.cmd --action=<start/restart/stop> --proxy=<proxy_name> --coin=<coin_name> --elevate=<true/false>", where "<proxy_name>" is name in configuration file and "<coin_name>" too.
If you run it without any params (and "ALLOW_MANUAL_SELECT" set to "true") you can manually select what ever you want to run.

In this version added ability to set an action. Now you can start, restart or stop proxy instance, what exacly you set, even if several different instances are running in a same time with a difference only by the port number, the script will find the appropriate instance on the configuration file and will work with it. You only need to specify the proxy name that is specified in the configuration.

Added possibility to make a comments in a configuration file.

Added logging. You can enable or disable it, set path, filename, etc...

Don't forget to change a configuration file.
![xmrig-proxy.cmd](https://github.com/equuleus/screenshots/blob/master/xmrig-proxy.cmd.png?raw=true "xmrig-proxy.cmd")
