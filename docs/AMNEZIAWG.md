# AmneziaWG support

WGDashboard manages AmneziaWG through the `awg` and `awg-quick` executables
available to the service. The NixOS module does not bundle an implementation:
the host selects its tools, kernel module, or userspace implementation through
the options documented in [NIXOS.md](NIXOS.md).

The dashboard understands the AWG 3.x interface settings
`HeaderProtectionKey`, `ContentPaddingAddition`, `RekeyAfterTime`,
`RekeyTimeout`, `RejectAfterTime`, `KeepaliveTimeout`,
`MaxHandshakeAttempts`, `RandomTrailers`, and `DisableCookies`. AWG peers may
also use a single value or an ascending uint16 range for
`PersistentKeepalive`. These values are preserved in downloaded configuration
files, AmneziaVPN exports, and QR codes.

New AWG 3.x fields are empty by default. WGDashboard does not choose a traffic
profile on behalf of the administrator. Enabling header protection requires a
base64-encoded 32-byte key and `S1` through `S4` values of at least 12. Range
fields accept either one integer or `lower-upper`; boolean fields accept
`on`/`off`.

Use mutually compatible tools and kernel/userspace implementations. In
particular, AWG 3.x changed the netlink representation of ranged keepalive
values, so a new kernel implementation must not be managed with old tools.
WGDashboard intentionally performs no package-version check because custom
implementations may use different version schemes.

Private keys, `HeaderProtectionKey`, and complete tunnel configurations are
runtime secrets. Keep them in WGDashboard's state directory or another secret
storage mechanism; do not put literal values into a Nix expression, where they
would be copied to the world-readable Nix store.
