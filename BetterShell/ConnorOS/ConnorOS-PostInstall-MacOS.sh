#!/usr/bin/env bash
echo "=== ConnorOS macOS Post-Install Starting ==="

# --- SECURITY ---
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
sudo defaults write /Library/Preferences/com.apple.alf stealthenabled -int 1
sudo spctl --master-enable

# --- PERFORMANCE ---
sudo pmset -a hibernatemode 0
sudo pmset -a sms 0
sudo trimforce enable

# --- UX ---
defaults write -g AppleInterfaceStyle Dark
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true
killall Finder

# --- CLOUD ---
rclone copy ~/ConnorOS/winutils.json onedrive:/ConnorOS
rclone copy ~/ConnorOS/winutils.json gdrive:/ConnorOS
aws s3 cp ~/ConnorOS/winutils.json s3://connoros-backups/winutils.json

# --- GAMING ---
rsync -av ~/Library/Application\ Support/GameSaves/ ~/OneDrive/GameSaves/

# --- DEV ---
git -C ~/.dotfiles pull
git -C ~/Repos status > ~/OneDrive/Reports/RepoHealth.txt

# --- MONITORING ---
system_profiler SPHardwareDataType > ~/OneDrive/Reports/MacHardware.txt
top -l 1 > ~/OneDrive/Reports/MacCPU.txt

# --- ORCHESTRATION ---
for host in nas-pc laptop-pc vm-pc; do
  scp ~/ConnorOS/winutils.json $host:/opt/ConnorOS/
  ssh $host "docker run --rm -v /opt/ConnorOS:/data connoros:latest"
done

# --- FUTURE-PROOFING ---
tar -czf ~/ConnorOS_Portable_macOS.tar.gz ~/ConnorOS

echo "=== ConnorOS macOS Post-Install Complete ==="
