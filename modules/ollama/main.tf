resource "helm_release" "ollama" {
 repository = "https://otwld.github.io/ollama-helm"
 chart = "ollama"
 version = "1.39.0"
 name = "ollama"
 create_namespace = true
 namespace = "ollama"
 values = [<<-EOF
persistentVolume:
  enabled: true
  size: 32Gi
  storageClass: local-path

service:
  type: LoadBalancer
  annotations:
    metallb.universe.tf/loadBalancerIPs: 10.206.101.10

resources:
  requests:
    memory: 4096Mi
  limits:
    cpu: 2000m
  
ollama:
  gpu:
    enabled: true
    type: amd
    number: 1
 EOF
]
}
