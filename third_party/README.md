# Third-Party IP (to be fetched when network is available)

Use pinned commits for reproducibility; clone into `third_party/` via `scripts/fetch_ip.sh`. Nothing is vendored yet.

| IP        | Source                                  | License | Notes |
|-----------|-----------------------------------------|---------|-------|
| LitePCIe  | https://github.com/enjoy-digital/litepcie | BSD     | PCIe endpoint + DMA; AXI-Lite BAR, AXI-Stream DMA |
| LiteDRAM  | https://github.com/enjoy-digital/litedram | BSD     | DDR3/DDR4 controller/PHY; Nexys Video preset available |
| LiteICLink/LiteVideo | https://github.com/enjoy-digital/liteiclink | BSD | HDMI/DVI TMDS encoder + video timing |
| LiteDMA (LiteX stream2mem/mem2stream) | https://github.com/enjoy-digital/litex | BSD | Stream↔mem DMA helpers |
| WB2AXIP (bridges, optional) | https://github.com/ZipCPU/wb2axip | BSD | Wishbone↔AXI bridges if needed |

Update this file with commit hashes after fetching. Keep GPL/LGPL IP out unless isolated.
