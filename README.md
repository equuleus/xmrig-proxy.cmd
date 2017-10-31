# xmrig-proxy.cmd
Windows Batch Script for automated start XMRig Proxy (https://github.com/xmrig/xmrig-proxy) with parameters

Run with available parameters: "xmrig-proxy.cmd MONERO" or "xmrig-proxy.cmd SUMOKOIN". If you run it without any params (and "ALLOW_MANUAL_SELECT" set to "true") you can manually select what ever you want to run.

If parameter not set, will use a default setting (MONERO).

If proxy ("xmrig-proxy.exe" file) already started, it will be automatically closed (killed process).

Don't forget to change "WALLET_MONERO" ("WALLET_SUMOKOIN") in a CMD to your personal wallets and other params at your choice. Good luck!

No one known bug currently.
