#!/bin/bash

echo Bootstrap ca.subhamho.me with ssh host certificate and timer based renewal

set -eou pipefail

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

echo 'Bootstrap ca'
env STEPPATH=/var/lib/step step ca bootstrap --ca-url https://ca.subhamho.me --fingerprint 39e64b7a3e385708d1ff230a2d0d6349f050cf60279069a06a3be1696af016a0

# ssh host certificate hostname and principals
echo "Fetching SSH Host certificate for hostname ${HOSTNAME} with principals: ${principals[*]}"
read -r -a more_principals -p "Enter additional certificate principals: "
principals=("${principals[@]}" "${more_principals[@]}")
echo "List of principals: ${principals[*]}"

echo 'Fetch ssh host certificate'
mkdir -p /etc/step/ssh
pushd /etc/step/ssh
env STEPPATH=/var/lib/step step ssh certificate --insecure --no-password --host "${principals[@]/#/--principal=}" ${HOSTNAME} ssh_host_ecdsa_key
popd

echo 'Install SSH user certificate'
tee /etc/ssh/ssh_user_key.pub <<EOF
ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBLGZzWhmsdhtW/tSy72/GT929lQT3WDPO6L91mDhikHAjLIsycPRL+SX0JMdK8rAKqj7CBW49Vu8Eg5D+U1lScg=
EOF

echo 'Add host and user certificates to sshd config'
if ! grep -qxF '# ca.subhamho.me Step CA' /etc/ssh/sshd_config; then 
  tee /etc/ssh/sshd_config <<-EOF
    # ca.subhamho.me Step CA
    HostKey /etc/step/ssh/ssh_host_ecdsa_key
    HostCertificate /etc/step/ssh/ssh_host_ecdsa_key-cert.pub
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
DynamicUser=true
ConfigurationDirectory=step/ssh
StateDirectory=step
ExecStartPre=chown ${CONFIGURATION_DIRECTORY}/ssh_host_ecdsa_key*
ExecStart=env HOME=${STATE_DIRECTORY} STEPPATH=${STATE_DIRECTORY} step ssh renew ${CONFIGURATION_DIRECTORY}/ssh_host_ecdsa_key-cert.pub ${CONFIGURATION_DIRECTORY}/ssh_host_ecdsa_key --force
ExecStartPost=+systemctl reload sshd
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
