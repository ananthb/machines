#!/bin/bash

echo Bootstrap ca.subhamho.me with ssh host certificate and timer based renewal

set -eou pipefail

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

echo 'Create step user and group'
useradd --comment "Step CA Client" --home /var/lib/step --create-home --system -s /usr/sbin/nologin --user-group

echo 'Give step group permission to reload sshd'
tee /etc/sudoers.d/10-step <<EOF
# Allow step to reload sshd
%step ALL = (root) NOPASSWD: /usr/bin/systemctl reload sshd
EOF

echo 'Bootstrap ca'
env STEPPATH=/var/lib/step sudo -Eu step ca bootstrap --ca-url https://ca.subhamho.me --fingerprint 39e64b7a3e385708d1ff230a2d0d6349f050cf60279069a06a3be1696af016a0

# ssh host certificate hostname and principals
echo "Fetching SSH Host certificate for hostname ${HOSTNAME} with principals: ${principals[*]}"
read -r -a more_principals -p "Enter additional certificate principals: "
principals=("${principals[@]}" "${more_principals[@]}")
echo "List of principals: ${principals[*]}"

echo 'Fetch ssh host certificate'
pushd /etc/ssh
env STEPPATH=/var/lib/step sudo -Eu step ssh certificate --insecure --no-password --host "${principals[@]/#/--principal=}" ${HOSTNAME} ssh_host_ecdsa_key
popd

echo 'Install SSH user certificate'
tee /etc/ssh/ssh_user_key.pub <<EOF
ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBLGZzWhmsdhtW/tSy72/GT929lQT3WDPO6L91mDhikHAjLIsycPRL+SX0JMdK8rAKqj7CBW49Vu8Eg5D+U1lScg=
EOF

echo 'Add host and user certificates to sshd config'
if ! grep -qxF '# ca.subhamho.me Step CA' /etc/ssh/sshd_config; then 
  tee /etc/ssh/sshd_config <<-EOF
    # ca.subhamho.me Step CA
    HostKey /etc/ssh/ssh_host_ecdsa_key
    HostCertificate /etc/ssh/ssh_host_ecdsa_key-cert.pub
    TrustedUserCAKeys /etc/ssh/ssh_user_key.pub
  EOF
fi

echo 'Install systemd service and timer to renew certificates'
tee /etc/systemd/system/step-ssh-renew.service <<EOF
[Unit]
Description=Step SSH Host Certificate renewal service
After=network.target tailscaled.service
Wants=network.target
Requires=tailscaled.service

[Service]
Type=oneshot
User=step
Group=step
Environment=STEPPATH=/var/lib/step
WorkingDirectory=/etc/ssh
ExecStart=step ssh renew ssh_host_ecdsa_key-cert.pub ssh_host_ecdsa_key --force
ExecStartPost=sudo systemctl reload sshd
EOF

tee /etc/systemd/system/step-ssh-renew.timer <<EOF
[Unit]
Description=Step renew SSH Host Certificate every week

[Timer]
OnCalendar=weekly
Persistent=true

[Install]
WantedBy=timers.target
EOF

systemctl reload sshd
