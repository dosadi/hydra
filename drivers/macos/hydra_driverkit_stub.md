# Hydra DriverKit Stub (macOS)

Placeholder notes for a DriverKit/SystemExtension bring-up:

- Create a DriverKit extension project in Xcode targeting PCI matching with vendor/device ID `0x1BAD/0x2024`.
- Implement `IOService` subclass that:
  - Matches on the PCI device, calls `mapDeviceMemoryWithIndex` for BAR0 (and BAR1 if present).
  - Exposes an `IOUserClient` interface with minimal methods: `read32(offset)`, `write32(offset)`, and a `getInfo` call returning BAR lengths/IRQ info.
- Enable non-cached mapping for BAR0/1; ensure 32-bit aligned accesses.
- Signing/provisioning: for dev use, disable user-client entitlements in the plist; production will require proper signing.
- Build: `xcodebuild -scheme HydraDriverKit -configuration Debug` (when the project exists).
- Not built in this repo; this file is guidance only.
