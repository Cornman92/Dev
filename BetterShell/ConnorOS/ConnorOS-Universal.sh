#!/usr/bin/env bash
echo "=== ConnorOS Universal Post-Install Starting ==="
OS="$(uname -s)"
case "$OS" in
  Linux) bash ~/ConnorOS/ConnorOS-PostInstall-Linux.sh ;;
  Darwin) bash ~/ConnorOS/ConnorOS-PostInstall-macOS.sh ;;
  *) echo "Unsupported OS: $OS" ;;
esac
