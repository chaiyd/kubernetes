#!/usr/bin/env sh

set -euo pipefail

version=1.21.0
local_ip=192.168.10.10

echo "---------------------------close，swap，selinux---------------------------"
# close swap,firewalld,selinux
systemctl stop firewalld
systemctl disable firewalld

swapoff -a && sed -i 's/.*swap.*/#&/' /etc/fstab
setenforce 0 && sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config

# install ipvsadm
yum install ipvsadm -y
cat <<EOF >/etc/sysconfig/modules/ipvs.modules
#!/bin/bash
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack_ipv4
EOF
chmod 755 /etc/sysconfig/modules/ipvs.modules && bash /etc/sysconfig/modules/ipvs.modules && lsmod | grep -e ip_vs -e nf_conntrack_ipv4

echo " ---------------------------install containerd---------------------------"
# containerd

yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum install -y containerd

cat <<EOF >/etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter
# Setup required sysctl params, these persist across reboots.
cat <<EOF >/etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
# Apply sysctl params without reboot
sysctl --system

# setting containerd
containerd config default >/etc/containerd/config.toml
# sed the containerd configuration
sed -i "s#k8s.gcr.io#registry.cn-hangzhou.aliyuncs.com/google_containers#g" /etc/containerd/config.toml
sed -i '/containerd.runtimes.runc.options/a\ \ \ \ \ \ \ \ \ \ \ \ SystemdCgroup = true' /etc/containerd/config.toml
#sed -i "s#https://registry-1.docker.io#https://registry.cn-hangzhou.aliyuncs.com#g"  /etc/containerd/config.toml

systemctl daemon-reload
systemctl enable --now containerd
systemctl restart containerd

echo "---------------------------install kubelet,kubeadm,kubectl---------------------------"

cat <<EOF >/etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
#sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
yum install -y kubelet-$version kubeadm-$version kubectl-$version
# 10-kubeadm.conf add container
sed -i '/Service/aEnvironment="KUBELET_KUBEADM_ARGS=--container-runtime=remote --runtime-request-timeout=15m --container-runtime-endpoint=unix:///run/containerd/containerd.sock --image-service-endpoint=unix:///run/containerd/containerd.sock" ' /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf
crictl config runtime-endpoint unix:///run/containerd/containerd.sock
crictl config image-endpoint unix:///run/containerd/containerd.sock
systemctl enable --now kubelet
systemctl restart kubelet

# echo "--------------------------init kubernetes------------------------"
# print kubeadm init-defaults configuration
# kubeadm config print init-defaults > kubeadm-init-config.yaml
# kubeadm init --config=kubeadm-init-config.yaml

# mkdir -p $HOME/.kube
# cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
# chown $(id -u):$(id -g) $HOME/.kube/config

# calico
# https://docs.projectcalico.org/getting-started/kubernetes/self-managed-onprem/onpremises
# Install Calico with Kubernetes API datastore, 50 nodes or less
# curl https://docs.projectcalico.org/manifests/calico.yaml -O
# Install Calico with Kubernetes API datastore, more than 50 nodes
# curl https://docs.projectcalico.org/manifests/calico-typha.yaml -o calico.yaml
# Download the Calico networking manifest for etcd.
# curl https://docs.projectcalico.org/manifests/calico-etcd.yaml -o calico.yaml