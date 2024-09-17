#!/bin/bash

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo or switch to root before running this script.'
    exit 1
fi

# Ensure shell is in non-interactive to avoid prompts
export DEBIAN_FRONTEND=noninteractive

help_message="
Usage: "$0" [OPTIONS]

Options:
  --help                 Display this help message
  --release              The frp version to be installed
"

platform="$(uname)"
architecture="$(uname -m)"
release="unknown"

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --help)
      echo "$help_message"
      exit 0
      ;;
    --release)
      release="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

if [[ "$release" == "unknown" ]]; then
    echo "The frp release number must be set! See https://github.com/fatedier/frp/releases."
    exit 1
fi

if [ "$platform" = "Linux" ]; then
    platform="linux"
elif [ "$platform" = "Darwin" ]; then
    platform="darwin"
fi

case "$architecture" in
    x86_64 | amd64) architecture="amd64";;
    aarch64 | arm64 | armv8*) architecture="arm64";;
    *) echo "(!) Architecture $architecture unsupported."; exit 1 ;;
esac

frp_package="frp_${release}_${platform}_${architecture}"

wget -qP /tmp "https://github.com/fatedier/frp/releases/download/v${release}/${frp_package}.tar.gz"
tar -zxvf "/tmp/${frp_package}.tar.gz" -C /tmp
mkdir -p /usr/local/etc/frp
cp "/tmp/${frp_package}/frps" /usr/local/bin/
curl -sSL -o /usr/local/etc/frp/frps.toml https://raw.githubusercontent.com/arctan95/frp/HEAD/frps.toml
curl -sSL -o /etc/systemd/system/frps.service https://raw.githubusercontent.com/arctan95/frp/HEAD/frps.service
rm -rf "/tmp/${frp_package}"
rm -rf "/tmp/${frp_package}.tar.gz"

systemctl daemon-reload
systemctl enable frps
systemctl start frps

echo "The frp server has been installed! Your must change your token in /usr/local/etc/frp/frps.toml for security reason!"
