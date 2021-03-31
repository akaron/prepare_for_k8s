#!/bin/bash
# For CentOS-7-x86_64-DVD_1908.iso and CentOS-7-x86_64-Everything-2009.iso
# run as root
set -ex

# set-up repositories and install docker
yum remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
yum install -y yum-utils python3 libselinux-python3 nfs-utils
yum-config-manager --add-repo  https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io
systemctl enable --now docker

# set up kubernetes repo and install
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

yum install -y kubelet-1.19.8 kubeadm-1.19.8 kubectl-1.19.8 --disableexcludes=kubernetes
systemctl enable --now kubelet


# use the systemd cgroup driver 
cat > /etc/docker/daemon.json <<EOF
{
    "exec-opts": ["native.cgroupdriver=systemd"],
    "log-driver": "json-file",
    "log-opts": {
    "max-size": "100m"
},
"storage-driver": "overlay2"
}
EOF

mkdir -p /etc/systemd/system/docker.service.d
systemctl daemon-reload
systemctl restart docker


# Letting iptables see bridged traffic 
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sysctl --system

# turn off swap
swapoff -a
sed -i.bak 's/\/dev\/mapper\/centos-swap/#\/dev\/mapper\/centos-swap/' /etc/fstab

# ufw (worker nodes may not need that many ports open)
# ufw default deny incoming
# ufw default allow outgoing
# ufw allow 22/tcp
# ufw allow 179/tcp
# ufw allow 2379/tcp
# ufw allow 2380/tcp
# ufw allow 6443/tcp
# ufw allow 10248/tcp
# ufw allow 10250/tcp
# ufw enable


# [optional] add to sudoers (and no password?)
# the purpose is for ansible to control this node as root
usermod -aG docker kai

# uncomment and modify these if necessary
echo \
"Run the following if necessary:
# # config private network if not yet
# # add the following in visudo
# kai    ALL=(ALL) NOPASSWD:ALL

Once these are ready, should able to install a k8s cluster."

echo \
    "For CentOS 7, edit the file /var/lib/kubelet/config.yaml
change the line of 'resolvConf' to
resolvConf: /etc/resolv.conf
"
