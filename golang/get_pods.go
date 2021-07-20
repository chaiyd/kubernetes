package main

import (
	"context"
	"flag"
	"fmt"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
)

func main() {
	var namespace string
	flag.StringVar(&namespace, "n", "", "命名空间,默认为空")
	flag.Parse()

	// 读取配置文件
	k8sConfig, err := clientcmd.BuildConfigFromFlags("", "kube/config")
	if err != nil {
		fmt.Printf("%v",err)
		return
	}

	// 创建一个k8s客户端
	clientSet, err := kubernetes.NewForConfig(k8sConfig)
	if err != nil {
		fmt.Printf("%v",err)
		return
	}

	// 查询k8s集群的节点信息，相当于命令：kubectl get nodes -o yaml, 如果没有管理员权限可能会失败，可以改成查Pods的接口
	// nodes, err := clientSet.CoreV1().Nodes().List(metav1.ListOptions{}) 老版本写法
	nodes, err := clientSet.CoreV1().Nodes().List(context.TODO(),metav1.ListOptions{})
	if err != nil {
		fmt.Printf("%v",err)
		return
	}
	for _,node := range nodes.Items {
		fmt.Println(node.Name)
	}

	pods, err := clientSet.CoreV1().Pods(namespace).List(context.TODO(), metav1.ListOptions{})
	if err != nil {
		fmt.Printf("pods%v",err)
		return
	}
	for _, pod := range pods.Items {
		fmt.Println(pod.Namespace,pod.Name, pod.Status.Phase)
	}
}
