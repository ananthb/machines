#!/bin/bash

set -eou pipefail

if [[ $EUID -ne 0 ]]; then
  exec sudo /bin/bash "$0" "$@"
fi

echo setting up SSH host certificates

step_bin="${STEP:-step}"
if ! [ -x "$(command -v $step_bin)" ]; then
  if [ -x "$(command -v step-cli)" ]; then
    step_bin=step-cli
  else
    echo "ensure step cli is in PATH or set $STEP env var pointing to step cli"
    exit 1
  fi
fi

echo 'bootstrap ca'
env STEPPATH=/var/lib/step $step_bin ca bootstrap --ca-url https://ca.subhamho.me --fingerprint 39e64b7a3e385708d1ff230a2d0d6349f050cf60279069a06a3be1696af016a0

# ssh host certificate hostname and principals
principals=("${HOSTNAME}")
echo "fetching SSH Host certificate for hostname ${HOSTNAME} with principals: ${principals[*]}"
read -r -a more_principals -p "Enter additional certificate principals: "
principals=("${principals[@]}" "${more_principals[@]}")
echo "final list of principals: ${principals[*]}"

mkdir -p /var/lib/step/ssh
pushd /var/lib/step/ssh
env STEPPATH=/var/lib/step $step_bin ssh certificate --insecure --no-password --host "${principals[@]/#/--principal=}" ${HOSTNAME} ssh_host_ecdsa_key
popd

echo 'installing SSH user certificate'
tee /etc/ssh/ssh_user_key.pub <<EOF
ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBLGZzWhmsdhtW/tSy72/GT929lQT3WDPO6L91mDhikHAjLIsycPRL+SX0JMdK8rAKqj7CBW49Vu8Eg5D+U1lScg=
EOF

echo 'adding host and user certificates to sshd config'
if ! grep -qxF '# ca.subhamho.me Step CA' /etc/ssh/sshd_config; then 
  tee /etc/ssh/sshd_config <<-EOF
    # ca.subhamho.me Step CA
    HostKey /var/lib/step/ssh/ssh_host_ecdsa_key
    HostCertificate /var/lib/step/ssh/ssh_host_ecdsa_key-cert.pub
    TrustedUserCAKeys /etc/ssh/ssh_user_key.pub
  EOF
fi

echo 'installing systemd service and timer to renew certificates'
tee /etc/systemd/system/step-ssh-renew.service <<EOF
[Unit]
Description=Step SSH Host Certificate renewal service
After=network.target tailscaled.service
Wants=network.target
Requires=tailscaled.service

[Service]
Type=oneshot
DynamicUser=true
StateDirectory=step
ExecStart=env HOME=${STATE_DIRECTORY} STEPPATH=${STATE_DIRECTORY} step ssh renew ${STATE_DIRECTORY}/ssh/ssh_host_ecdsa_key-cert.pub ${STATE_DIRECTORY}/ssh/ssh_host_ecdsa_key --force
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

systemctl daemon-reload
systemctl enable step-ssh-renew.timer
systemctl reload sshd
