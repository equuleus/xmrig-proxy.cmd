# xmrig-proxy.cmd
Windows Batch Script for automated start XMRig Proxy (https://github.com/xmrig/xmrig-proxy) with parameters

Run with currently available parameters: "xmrig-proxy.cmd MONERO" or "xmrig-proxy.cmd SUMOKOIN". 

If parameter not set, will use a default setting (MONERO).

If proxy ("xmrig-proxy.exe" file) already started, it will be automatically closed (killed process).

Don't forget to change "WALLET" in a CMD. Good luck!

P.S. Known bug: if cmd run without administartor rights it will try to get it and restart. You can chahge ":TEST" to ":START" in a 40 line of code to run it withoud admin right check and elevate. Should fix it in a few days.
