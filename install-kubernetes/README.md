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

## metrics
- officaial docs
  - [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics.git)
    
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