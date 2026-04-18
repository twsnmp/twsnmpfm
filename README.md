# twsnmpfm

[日本語版 (Japanese)](README_ja.md)

TWSNMP For Mobile - A comprehensive network management tool for your pocket.

## Overview

TWSNMP For Mobile is the mobile version of the classic SNMP manager "TWSNMP". It allows network administrators to monitor and manage their network infrastructure directly from their mobile devices (iOS, Android) and desktops (macOS).

## Features

- **Node Management**: Easily add, edit, and categorize network nodes with custom icons (Server, PC, LAN, Cloud).
- **Connectivity Checks**: 
  - Periodic and manual PING response confirmation.
  - SSL/TLS Server Certificate expiration and validity checks (HTTPS, etc.).
- **SNMP Monitoring Tools**:
  - **MIB Browser**: Explore the MIB tree and retrieve object values using SNMP v1/v2c.
  - **Traffic Monitor**: Real-time traffic volume measurement with interactive charts.
  - **Virtual Panel**: Visual status display of LAN ports (Up/Down status based on ifIndex).
  - **Host Resources**: Monitor CPU, Memory, and Disk usage via Host Resource MIB.
  - **Process List**: View running processes on the target node.
  - **Port List**: Check active TCP/UDP port status.
- **Server Testing**:
  - Send Syslog messages and SNMP Traps for testing.
  - Monitor DHCP messages on the network.
  - Test E-mail (SMTP) functionality.
- **Network Search Utilities**:
  - DNS lookup (A, AAAA, PTR, etc.) with IP search.
  - MAC Address vendor lookup with a built-in database (OUI).
- **Modern UI**:
  - Supports Light and Dark modes.
  - Intuitive navigation based on the "TWSNMP Blueprint" design system.
  - Multilingual support (English and Japanese).

## Status
First version already released.

- **iOS**: [App Store](https://apps.apple.com/jp/app/twsnmp-for-mobile/id1630463521)
- **Android**: [Google Play](https://play.google.com/store/apps/details?id=jp.co.twsie.twsnmpfm)

## How to Build

To build the application from source, ensure you have the [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.

1. **Clone the repository**:
   ```bash
   git clone https://github.com/twsnmp/twsnmpfm.git
   cd twsnmpfm
   ```
2. **Install dependencies**:
   ```bash
   flutter pub get
   ```
3. **Run the app**:
   ```bash
   flutter run
   ```
4. **Build for specific platforms**:
   - **Android**: `flutter build apk`
   - **iOS**: `flutter build ios`
   - **macOS**: `flutter build macos`

## How to Use

1. **Adding Nodes**: Tap the **+** button on the main screen to add a new device. Enter the Name, IP address, and SNMP Community string.
2. **Monitoring Status**: The main list displays icons for PING and Certificate status. A green check indicates OK, while red or amber indicates issues.
3. **Accessing Tools**: Tap the **three-dot menu** on a node card to access specific tools like the MIB Browser, Traffic Monitor, or Virtual Panel.
4. **Mass Checks**: Use the **Play icon** in the top bar to run PING or Certificate checks for all configured nodes manually.
5. **Search**: Tap the **Search icon** in the top bar for DNS lookup or MAC address vendor search.
6. **Settings**: Use the **Gear icon** in the top bar to adjust check intervals, timeouts, and theme preferences.

## Copyright

see ./LICENSE

```
Copyright 2022-2026 Masayuki Yamai
```
