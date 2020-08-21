# kube-state-metrics

[kube-state-metrics](https://github.com/kubernetes/kube-state-metrics.git)

* 拉取官方配置yaml文件
* 仅在service.yaml增加
```  
annotations:
  prometheus.io/scrape: 'true'
```
