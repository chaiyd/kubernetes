# cloud-provider-alibaba-cloud

## 使用

#### 若集群已经在使用中，可使用以下
- cloud-controller-manager.conf
  ```
  $CA_DATA
  cat /etc/kubernetes/pki/ca.crt|base64 -w 0
  # 修改完配置,文件需放入目录/etc/kubernetes
  ```
- cloud-config.conf
  ```shell
  base64 AccessKey & AccessKeySecret
  echo -n "$AccessKeyID" |base64
  echo -n "$AcceessKeySecret"|base64
  ```

- os: CentOS7
- 修改vim /usr/lib/systemd/system/kubelet.service
  ```
  [Unit]
  Description=kubelet: The Kubernetes Node Agent
  Documentation=https://kubernetes.io/
  [Service]
  Environment="KUBELET_CLOUD_PROVIDER_ARGS=--cloud-provider=external --hostname-override=${REGION_ID}.${INSTANCE_ID} --provider-id=${REGION_ID}.${INSTANCE_ID}"
  ```
- `${REGION_ID}.${INSTANCE_ID}` 获取
    ```
    META_EP=http://100.100.100.200/latest/meta-data
    echo `curl -s $META_EP/region-id`.`curl -s $META_EP/instance-id`
    ```
- Kubernetes add providerID
  - providerID= `${REGION_ID}.${INSTANCE_ID}`
    ```shell
    kubectl patch node ${NODE_NAME} -p '{"spec":{"providerID": "cn-shanghai.i-uf6"}}'
    ```
- Kubernetes add label
  ```
  kubectl label nodes ${NODE_NAME} node-role.kubernetes.io/master=
  ```

## others

```
# 查看node providerID
kubectl get node -o yaml|grep providerID
# 删除providerID
kubectl delete node ${NODE_NAME}

# 重启kubelet
systemctl daemon-reload
systemctl restart kubelet

kubeadm token create --print-join-command
```


