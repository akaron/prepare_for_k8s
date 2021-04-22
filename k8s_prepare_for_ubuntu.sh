#!/bin/bash
# For ubuntu-18.04.5-live-server-amd64.iso
set -ex

# set-up repositories
apt-get update
apt-get upgrade -y
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release ntp nfs-common
# add nfs-common if use nfs-provisioner
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
add-apt-repository "deb https://apt.kubernetes.io/ kubernetes-xenial main"

# install and config docker engine
apt-get update
apt-get install -y docker-ce=5:19.03.11~3-0~ubuntu-bionic \
  docker-ce-cli=5:19.03.11~3-0~ubuntu-bionic \
  containerd.io=1.2.13-2 \
  kubeadm=1.19.8-00 \
  kubectl=1.19.8-00 \
  kubelet=1.19.8-00
apt-mark hold kubelet kubeadm kubectl

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
#cp /etc/fstab /etc/fstab.bak
#sed 's/\/swap.img/#\/swap.img/' /etc/fstab >/etc/fstabo
sed -i.bak 's/\/swap.img/#\/swap.img/' /etc/fstab
swapoff -a

# ufw (worker nodes may not need that many ports open)
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 179/tcp
ufw allow 2379/tcp
ufw allow 2380/tcp
ufw allow 6443/tcp
ufw allow 10248/tcp
ufw allow 10250/tcp
ufw enable


# [optional] add to sudoers (and no password?)
# the purpose is for ansible to control this node as root
usermod -aG docker ubuntu

# uncomment and modify these if necessary
echo \
"Run the following if necessary:
# # change IP (modify corresponding file in /etc/netplan)
# hostnamectl set-hostname k8s-master1
# # config private network (assume external one has been configured)
# # add the following in visudo
# ubuntu ALL=(ALL) NOPASSWD:ALL

Once these are ready, should able to install a k8s cluster."

