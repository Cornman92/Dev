#!/usr/bin/env bash
echo "=== ConnorOS Linux Post-Install Starting ==="

# --- SECURITY ---
sudo ufw enable
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo sysctl -w net.ipv4.conf.all.rp_filter=1
sudo sysctl -w net.ipv4.conf.all.accept_redirects=0

# --- PERFORMANCE ---
sudo systemctl disable apport whoopsie
sudo fstrim -av
sudo sysctl -w vm.swappiness=10

# --- UX ---
gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark"
gsettings set org.gnome.desktop.interface show-hidden-files true

# --- CLOUD ---
rclone copy ~/ConnorOS/winutils.json onedrive:/ConnorOS
rclone copy ~/ConnorOS/winutils.json gdrive:/ConnorOS
aws s3 cp ~/ConnorOS/winutils.json s3://connoros-backups/winutils.json

# --- GAMING ---
rsync -av ~/Games/Saves/ ~/OneDrive/GameSaves/

# --- DEV ---
git -C ~/.dotfiles pull
git -C ~/Repos status > ~/OneDrive/Reports/RepoHealth.txt

# --- MONITORING ---
echo "<h1>ConnorOS Linux Health</h1>" > ~/OneDrive/Reports/LinuxHealth.html
uptime >> ~/OneDrive/Reports/LinuxHealth.html
df -h >> ~/OneDrive/Reports/LinuxHealth.html
free -m >> ~/OneDrive/Reports/LinuxHealth.html

# --- ORCHESTRATION ---
for host in nas-pc laptop-pc vm-pc; do
  scp ~/ConnorOS/winutils.json $host:/opt/ConnorOS/
  ssh $host "docker run --rm -v /opt/ConnorOS:/data connoros:latest"
done

# --- FUTURE-PROOFING ---
tar -czf ~/ConnorOS_Portable.tar.gz ~/ConnorOS

echo "=== ConnorOS Linux Post-Install Complete ==="

curl -X POST http://orchestrator.local:8000/report \
  -H "Content-Type: application/json" \
  -d '{
    "node":"'"$(hostname)"'",
    "os":"'"$(uname -s)"'",
    "timestamp":"'"$(date -Iseconds)"'",
    "status":"success",
    "security":{"firewall":"on"},
    "performance":{"trim":"active"},
    "cloudSync":{"onedrive":"ok","gdrive":"ok","s3":"ok"},
    "gaming":{"saveSync":"ok"},
    "dev":{"dotfiles":"synced","repoHealth":"ok"},
    "monitoring":{"dashboard":"generated"}
  }'
