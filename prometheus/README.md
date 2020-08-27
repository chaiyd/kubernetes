# prometheus

* 存放prometheus yaml 以及依赖的metrics

## kube-state-metrics
* 用于获取容器各项指标


## grafana模板
https://grafana.com/grafana/dashboards/12870

* 下列版本测试没有问题，其他版本请自行测试
```
k8s version 1.16.10
node-exporter version v1.0.1
prometheus version 2.19.2
grafana version 7.1.0
```

![grafana-1](../images/grafana-1.png)

![grafana-2](../images/grafana-2.png)

