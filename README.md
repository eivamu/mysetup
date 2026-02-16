# mysetup

Personal setup and configuration files for machines I use.

## Structure

```
shared/          # Platform-agnostic configs
  client/        # Client-specific (desktop/laptop)
  server/        # Server-specific
macos/           # macOS-specific configs
  client/
  server/
linux/           # Linux-specific configs
  client/
  server/
windows/         # Windows-specific configs
  client/
  server/
scripts/         # Setup and install scripts
```

## Usage

Configs are organized by platform (`shared`, `macos`, `linux`, `windows`) and role (`client`, `server`). Platform-agnostic settings go in `shared/`, with platform-specific overrides in their respective directories.
