# Third-Party IP (to be fetched when network is available)

Use pinned commits for reproducibility; IP is tracked as git submodules under `third_party/` and initialized via `scripts/fetch_ip.sh` (a thin wrapper around `git submodule update`).

| IP        | Source                                    | License | Commit                                 | Notes |
|-----------|-------------------------------------------|---------|----------------------------------------|-------|
| LitePCIe  | https://github.com/enjoy-digital/litepcie | BSD     | 5a50f83f33b7ceea75a0b226893d3b74c2361e79 | PCIe endpoint + DMA; AXI-Lite BAR, AXI-Stream DMA |
| LiteDRAM  | https://github.com/enjoy-digital/litedram | BSD     | 8ca007a0372788d3d64cdc196220e729e6e940e3 | DDR3/DDR4 controller/PHY; Nexys Video preset available |
| LiteICLink/LiteVideo | https://github.com/enjoy-digital/liteiclink | BSD | 679befc2271e64297345b15e974b2d2fdcd8fad5 | HDMI/DVI TMDS encoder + video timing |
| LiteDMA (LiteX stream2mem/mem2stream) | https://github.com/enjoy-digital/litex | BSD | 10c52e742094ce72884fb7f0711576a4f6fb4892 | Stream↔mem DMA helpers |

These hashes should match the submodule commits recorded in the Git tree. Keep GPL/LGPL IP out unless isolated.

