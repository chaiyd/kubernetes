# ELK
* elk 采用es，filebeat，kibana，进行日志采集
* logstash.yaml 仅用来存档，并未使用
* images版本使用7.8.1
* elasticsearch已关闭集群模式，如有需要请自行修改，请自行挂载数据
* 各配置已经过测试
* filebeat已开启多行合并，官方有建议，在日志推送到logstash之前进行日志合并已免日志遭到破外
* 目前对日志没有过高要求，filebeat多行合并，基本达到要求，故未使用logstash
