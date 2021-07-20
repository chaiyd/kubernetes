package main

import (
	"context"
	"flag"
	"fmt"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes/scheme"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/tools/clientcmd"
)

func main() {
	// namespace
	var namespace string
	var podname string
	// 端口号
	var port int
	flag.StringVar(&namespace, "n", "", "命名空间,默认为空")
	flag.StringVar(&podname, "p", "", "podname,默认为空")
	flag.IntVar(&port, "P", 3306, "端口号,默认为空")
	flag.Parse()

	fmt.Println("Prepare config object.")

	// 加载k8s配置文件，生成Config对象
	config, err := clientcmd.BuildConfigFromFlags("", "kube/config")
	if err != nil {
		panic(err)
	}

	config.APIPath = "api"
	config.GroupVersion = &corev1.SchemeGroupVersion
	config.NegotiatedSerializer = scheme.Codecs

	fmt.Println("Init RESTClient.")

	// 定义RestClient，用于与k8s API server进行交互
	restClient, err := rest.RESTClientFor(config)
	if err != nil {
		panic(err)
	}

	fmt.Println("Get Pods in cluster.")

	// 获取pod列表。
	result := &corev1.PodList{}
	if err := restClient.
		Get().
		Namespace(namespace).
		Resource("pods").
		VersionedParams(&metav1.ListOptions{Limit: 500}, scheme.ParameterCodec).
		Do(context.TODO()).
		Into(result); err != nil {
		panic(err)
	}

	fmt.Println("Print all listed pods.")

	// 打印所有获取到的pods资源，输出到标准输出
	for _, d := range result.Items {
		fmt.Printf("NAMESPACE: %v NAME: %v \t STATUS: %v \n", d.Namespace, d.Name, d.Status.Phase)
	}
}
