# kubernetes install

## containerd
- kubernetes is about to dockershim
- use containerd install kubernetes
- use ctr
    - kubernetes use namespaces k8s.io by defaults
  ```shell
  ctr namespace ls
  ctr -n k8s.io images check
  ctr -n k8s.io images import app.tar
   ```

## kubernetes containerd kubeadm
- ipvs,containerd,calico
- Add the configuration to kubelet, otherwise unexpected errors will occur when kubeadm is reset
  ```shell
  #/usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf 
  #Environment="KUBELET_KUBEADM_ARGS=--container-runtime=remote --runtime-request-timeout=15m --container-runtime-endpoint=unix:///run/containerd/containerd.sock --image-service-endpoint=unix:///run/containerd/containerd.sock"
  sed -i '/Service/aEnvironment="KUBELET_KUBEADM_ARGS=--container-runtime=remote --runtime-request-timeout=15m --container-runtime-endpoint=unix:///run/containerd/containerd.sock --image-service-endpoint=unix:///run/containerd/containerd.sock" ' /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf
  ```

## kubeadm init
- init
    - kubeadm config print init-defaults > kubeadm-init-config.yaml
    - kubeadm init --config kubeadm-init-config.yaml --upload-certs
  ```shell
  ---
  # setting containerd
  nodeRegistration:
    criSocket: /var/run/containerd/containerd.sock
  ---
  # setting ipvs
  apiVersion: kubeproxy.config.k8s.io/v1alpha1
  kind: KubeProxyConfiguration
  mode: ipvs
  # setting cgroupDriver systemd
  ---
  apiVersion: kubelet.config.k8s.io/v1beta1
  kind: KubeletConfiguration
  cgroupDriver: systemd
  ```
  
## kubeadm add new master node
- create new token
  ```
  # kubeadm token create --print-join-command
  kubeadm join kubernetes:6443 --token oaxxbj.pmaxxxxxxx6buyr3     --discovery-token-ca-cert-hash sha256:2aad45exxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxf20b7b74385d6ab170d7d98 
  ```
- master node new cert
  ```
  # kubeadm init phase upload-certs --upload-certs
  5343f09e20xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx1e33b29b3247cca
  ```
- add new master
  ```
  # kubeadm join kubernetes:6443 --token oaxxbj.pmaxxxxxxx6buyr3 \
      --discovery-token-ca-cert-hash sha256:2aad45exxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxf20b7b74385d6ab170d7d98 \
      --control-plane --certificate-key 5343f09e20xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx1e33b29b3247cca
  ```
- add new node
  ```
  # kubeadm join kubernetes:6443 --token oaxxbj.pmaxxxxxxx6buyr3 \
      --discovery-token-ca-cert-hash sha256:2aad45exxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxf20b7b74385d6ab170d7d98
  ```


## Creating Highly Available clusters with kubeadm
- kubeadm init --config kubeadm-config.yaml --upload-certs
- official docs
    - [Bootstrapping clusters with kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/)
  ```shell
  sudo kubeadm join 192.168.0.200:6443 --token 9vr73a.a8uxyaju799qwdjv \
  --discovery-token-ca-cert-hash sha256:7c2e69131a36ae2a042a339b33381c6d0d43887e2de83720eff5359e26aec866 \
  --control-plane \
  --certificate-key f8902e114ef118304e561c3ecd4d0b543adc226b7a07f675f56564185ffe0c07
  ```
    - The --control-plane flag tells kubeadm join to create a new control plane.
    - The --certificate-key ... will cause the control plane certificates to be downloaded from the kubeadm-certs Secret in the cluster and be decrypted using the given key

## calico
- View Official docs
- If you are using pod CIDR 192.168.0.0/16, skip to the next step. If you are using a different pod CIDR with kubeadm, no changes are required - Calico will automatically detect the CIDR based on the running configuration. For other platforms, make sure you uncomment the `CALICO_IPV4POOL_CIDR` variable in the manifest and set it to the same value as your chosen pod CIDR.
```shell
# https://docs.projectcalico.org/getting-started/kubernetes/self-managed-onprem/onpremises
# Install Calico with Kubernetes API datastore, 50 nodes or less
# curl https://docs.projectcalico.org/manifests/calico.yaml -O
# Install Calico with Kubernetes API datastore, more than 50 nodes
# curl https://docs.projectcalico.org/manifests/calico-typha.yaml -o calico.yaml
# Download the Calico networking manifest for etcd.
# curl https://docs.projectcalico.org/manifests/calico-etcd.yaml -o calico.yaml
```

### 排查 k8s 集群 master 节点无法正常工作的问题
- 搭建的是 k8s 高可用集群，用了 3 台 master 节点，2 台 master 节点宕机后，仅剩的 1 台无法正常工作。
- 运行 kubectl get nodes 命令出现下面的错误
```
The connection to the server k8s-api:6443 was refused - did you specify the right host or port?
注：k8s-api 对应的就是这台 master 服务器的本机 IP 地址。
```

- 运行 netstat -lntp 命令发现 kube-apiserver 根本没有运行，同时发现 etcd 与 kube-proxy 也没运行。
```
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name    
tcp        0      0 127.0.0.1:33807         0.0.0.0:*               LISTEN      602/kubelet         
tcp        0      0 0.0.0.0:111             0.0.0.0:*               LISTEN      572/rpcbind         
tcp        0      0 127.0.0.1:10257         0.0.0.0:*               LISTEN      3229/kube-controlle
tcp        0      0 127.0.0.1:10259         0.0.0.0:*               LISTEN      3753/kube-scheduler
tcp        0      0 127.0.0.53:53           0.0.0.0:*               LISTEN      571/systemd-resolve
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      1644/sshd           
tcp        0      0 127.0.0.1:10248         0.0.0.0:*               LISTEN      602/kubelet         
tcp6       0      0 :::111                  :::*                    LISTEN      572/rpcbind         
tcp6       0      0 :::10250                :::*                    LISTEN      602/kubelet         
tcp6       0      0 :::10251                :::*                    LISTEN      3753/kube-scheduler
tcp6       0      0 :::10252                :::*                    LISTEN      3229/kube-controlle
```

- 通过 docker ps 命令发现 etcd , kube-apiserver, kube-proxy 这 3 个容器都没有运行，etcd 容器在不停地启动->失败->重启->又失败......，查看容器日志发现下面的错误：
```
etcdserver: publish error: etcdserver: request timed out
rafthttp: health check for peer 611e58a32a3e3ebe could not connect: dial tcp 10.0.1.252:2380: i/o timeout (prober "ROUND_TRIPPER_SNAPSHOT")
rafthttp: health check for peer 611e58a32a3e3ebe could not connect: dial tcp 10.0.1.252:2380: i/o timeout (prober "ROUND_TRIPPER_RAFT_MESSAGE")
rafthttp: health check for peer cc00b4912b6442df could not connect: dial tcp 10.0.1.82:2380: i/o timeout (prober "ROUND_TRIPPER_SNAPSHOT")
rafthttp: health check for peer cc00b4912b6442df could not connect: dial tcp 10.0.1.82:2380: i/o timeout (prober "ROUND_TRIPPER_RAFT_MESSAGE")
raft: 12637f5ec2bd02b8 is starting a new election at term 254669
etcd 启动失败是由于 etcd 在 3 节点集群模式在启动却无法连接另外 2 台 master 节点的 etcd ，要解决这个问题需要改为单节点集群模式。开始不知道如何将 etcd 改为单节点模式，后来在网上找到 2 个参数 --initial-cluster-state=new 与 --force-new-cluster ，在 /etc/kubernetes/manifests/etcd.yaml 中给 etcd 命令加上这 2 个参数，并重启服务器后，master 节点就能正常运行了。

containers:
- command:
    - etcd
    - --advertise-client-urls=https://10.0.1.81:2379
    - --cert-file=/etc/kubernetes/pki/etcd/server.crt
    - --client-cert-auth=true
    - --data-dir=/var/lib/etcd
    - --initial-advertise-peer-urls=https://10.0.1.81:2380
    - --initial-cluster=k8s-master0=https://10.0.1.81:2380
    - --initial-cluster-state=new
      ......
```
- master 正常运行后，需要去掉刚刚添加的这 2 个 etcd 参数。


## metrics
- officaial docs
    - [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics.git)
        - [examples](https://github.com/kubernetes/kube-state-metrics/tree/master/examples)

    - [metrics-server](https://github.com/kubernetes-sigs/metrics-server.git)
      ```
      kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
  
      kubectl logs -f metrics-server-7644b87b46-rx962 -n kube-system
      I1130 21:21:37.127526       1 serving.go:325] Generated self-signed cert (/tmp/apiserver.crt, /tmp/apiserver.key)
      I1130 21:21:38.378578       1 secure_serving.go:197] Serving securely on [::]:4443
      I1130 21:21:38.378794       1 requestheader_controller.go:169] Starting RequestHeaderAuthRequestController
      I1130 21:21:38.378861       1 shared_informer.go:240] Waiting for caches to sync for RequestHeaderAuthRequestController
      I1130 21:21:38.378938       1 dynamic_serving_content.go:130] Starting serving-cert::/tmp/apiserver.crt::/tmp/apiserver.key
      I1130 21:21:38.379015       1 tlsconfig.go:240] Starting DynamicServingCertificateController
      I1130 21:21:38.379116       1 configmap_cafile_content.go:202] Starting client-ca::kube-system::extension-apiserver-authentication::client-ca-file
      I1130 21:21:38.379175       1 shared_informer.go:240] Waiting for caches to sync for client-ca::kube-system::extension-apiserver-authentication::client-ca-file
      I1130 21:21:38.379254       1 configmap_cafile_content.go:202] Starting client-ca::kube-system::extension-apiserver-authentication::requestheader-client-ca-file
      I1130 21:21:38.379318       1 shared_informer.go:240] Waiting for caches to sync for client-ca::kube-system::extension-apiserver-authentication::requestheader-client-ca-file
      I1130 21:21:38.479382       1 shared_informer.go:247] Caches are synced for client-ca::kube-system::extension-apiserver-authentication::client-ca-file
      I1130 21:21:38.479412       1 shared_informer.go:247] Caches are synced for client-ca::kube-system::extension-apiserver-authentication::requestheader-client-ca-file
      I1130 21:21:38.479382       1 shared_informer.go:247] Caches are synced for RequestHeaderAuthRequestController  
      # a few seconds logging nothing, then pod is restarting right after logging those last lines:   
      I1130 21:22:04.475279       1 configmap_cafile_content.go:223] Shutting down client-ca::kube-system::extension-apiserver-authentication::client-ca-file
      I1130 21:22:04.475333       1 tlsconfig.go:255] Shutting down DynamicServingCertificateController
      I1130 21:22:04.475339       1 dynamic_serving_content.go:145] Shutting down serving-cert::/tmp/apiserver.crt::/tmp/apiserver.key
      I1130 21:22:04.475365       1 secure_serving.go:241] Stopped listening on [::]:4443
      ```

    - The container args on my metrics-server.yaml are:
        - https://github.com/kubernetes-sigs/metrics-server/issues/637
      ```shell
      spec:
        containers:
          - args:
              - --cert-dir=/tmp
              - --secure-port=4443
              - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
              - --kubelet-use-node-status-port
              - --kubelet-insecure-tls
            image: k8s.gcr.io/metrics-server/metrics-server:v0.4.4
            # image: chaiyd/metrics-server:v0.4.4
      ```


## MetalLB
- https://metallb.universe.tf/
- Kubernetes does not offer an implementation of network load-balancers (Services of type LoadBalancer) for bare metal clusters.
- configmap.yaml
  ```yaml
  apiVersion: v1
  kind: ConfigMap
  metadata:
    namespace: metallb-system
    name: config
  data:
    config: |
      address-pools:
        - name: default
      protocol: layer2
        addresses:
          - 192.168.6.240-192.168.6.245
  ```
