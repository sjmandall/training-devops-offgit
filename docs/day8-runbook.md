###Day 8 Runbook

##Task
Linux networking, firewall, and hardening.

##Objective
Configure firewall rules to allow only required ports, verify open ports before and after changes, review Apache access and error logs, lock down permissions of the web root, and enable basic Fail2Ban protection for SSH if allowed.

Expected Deliverables
1. ss -tulpen output saved before and after firewall changes.
2. Firewall configuration evidence.
3. scripts/log_review.sh summarizing recent Apache errors and top client IPs.
4. Web-root permission evidence.
5. Fail2Ban status evidence if enabled.

Environment
- Ubuntu or Debian-based Linux system
- Apache web server
- Project directory: ~/project

Step 1: Create required folders
cd ~/project
mkdir -p docs scripts logs

Step 2: Save current listening ports before firewall changes
ss -tulpen > docs/ss-before.txt

Step 3: Review current firewall status
sudo ufw status verbose

Step 4: Configure firewall
Set a restrictive inbound policy and allow only required services.

Commands:
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable
sudo ufw status numbered > docs/firewall-status.txt

Step 5: Save listening ports after firewall changes
ss -tulpen > docs/ss-after.txt

Step 6: Lock down web-root permissions
Use controlled ownership and safe permissions for Apache-served files.

Commands:
sudo chown -R webadmin:www-data /var/www/website
sudo find /var/www/website -type d -exec chmod 755 {} \;
sudo find /var/www/website -type f -exec chmod 644 {} \;
ls -ld /var/www/website > docs/webroot-permissions.txt
ls -l /var/www/website >> docs/webroot-permissions.txt

Step 7: Create Apache log review script
Create a script that summarizes the latest Apache errors and the top IPs found in the access log.

Command:
cat > ~/project/scripts/log_review.sh <<'LOGEOF'
#!/bin/bash
set -e

ACCESS_LOG="/var/log/apache2/access.log"
ERROR_LOG="/var/log/apache2/error.log"
OUTFILE="$HOME/project/logs/apache-log-summary.txt"

mkdir -p "$(dirname "$OUTFILE")"

{
  echo "Apache Log Review Summary"
  echo "Generated: $(date)"
  echo

  echo "Last 20 Apache errors"
  if [ -f "$ERROR_LOG" ]; then
    tail -n 20 "$ERROR_LOG"
  else
    echo "Error log not found: $ERROR_LOG"
  fi

  echo
  echo "Top 10 client IPs from access log"
  if [ -f "$ACCESS_LOG" ]; then
    awk '{print $1}' "$ACCESS_LOG" | sort | uniq -c | sort -nr | head -10
  else
    echo "Access log not found: $ACCESS_LOG"
  fi
} > "$OUTFILE"

echo "Summary written to $OUTFILE"
LOGEOF

Step 8: Make the script executable and run it
chmod +x ~/project/scripts/log_review.sh
~/project/scripts/log_review.sh

Step 9: Install and enable Fail2Ban for SSH if allowed
Fail2Ban monitors service logs for repeated failed attempts and temporarily bans abusive IPs through the firewall.

Install commands:
sudo apt update
sudo apt install -y fail2ban
sudo systemctl enable --now fail2ban

Step 10: Create local Fail2Ban override configuration
Do not change ownership of /etc/fail2ban. Keep it root-owned and create jail.local using sudo.

Command:
sudo tee /etc/fail2ban/jail.local > /dev/null <<'F2BEOF'
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 3
ignoreip = 127.0.0.1/8 ::1

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
F2BEOF

Step 11: Restart Fail2Ban and save evidence
sudo systemctl restart fail2ban
sudo fail2ban-client status > docs/fail2ban-status.txt
sudo fail2ban-client status sshd >> docs/fail2ban-status.txt

Step 12: Verification commands
Check listening ports:
ss -tulpen

Check UFW rules:
sudo ufw status numbered

Check Apache summary output:
cat logs/apache-log-summary.txt

Check Fail2Ban:
sudo fail2ban-client status
sudo fail2ban-client status sshd

Check web-root permissions:
cat docs/webroot-permissions.txt

Expected Results
- Only required ports such as SSH, HTTP, and HTTPS are explicitly allowed through UFW.
- docs/ss-before.txt and docs/ss-after.txt contain saved socket information.
- docs/firewall-status.txt contains firewall evidence.
- scripts/log_review.sh exists and produces logs/apache-log-summary.txt.
- Web-root permissions are tightened and recorded.
- Fail2Ban is enabled and the sshd jail is active if permitted in the lab.

Files Generated
- docs/ss-before.txt
- docs/ss-after.txt
- docs/firewall-status.txt
- docs/webroot-permissions.txt
- docs/fail2ban-status.txt
- scripts/log_review.sh
- logs/apache-log-summary.txt


Notes
- Always allow SSH before enabling UFW so remote access is not blocked.
- Do not run chown on /etc/fail2ban; configuration there must remain root-owned.
- Fail2Ban is not a replacement for a firewall. It works with firewall rules to automatically ban abusive IPs based on log activity.

Conclusion
Day 8 completed by restricting firewall access, collecting before/after socket evidence, reviewing Apache logs through a script, tightening web-root permissions, and enabling basic Fail2Ban protection for SSH.>
