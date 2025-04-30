resource "helm_release" "ollama" {
  repository = "https://otwld.github.io/ollama-helm"
  chart = "ollama"
  version = "1.15.0"
  name = "ollama"
  create_namespace = true
  namespace = "ollama"

  set {
    name = "persistentVolume.enabled"
    value = true
  }

  set {
    name = "persistentVolume.size"
    value = "5Gi"
  }

  set {
    name = "persistentVolume.storageClass"
    value = "longhorn"
  }

  set {
    name = "service.type"
    value = "LoadBalancer"
  }

  set {
    name = "service.annotations.metallb\\.universe\\.tf\\/loadBalancerIPs"
    value = "10.206.101.10"
  }

  set {
    name = "ollama.models.pull[0]"
    value = "llama3.2"
  }

  set {
    name = "ollama.models.run[0]"
    value = "llama3.2"
  }
  
  set{
    name = "resources.requests.memory"
    value = "4096Mi"
  }
}

resource "helm_release" "openwebui" {
  repository = "https://helm.openwebui.com/"
  chart = "open-webui"
  name = "open-webui"
  create_namespace = true
  namespace = "open-webui"

  set {
    name = "ollama.enabled"
    value = false
  }

  set {
    name = "ollamaUrls[0]"
    value = "http://10.206.101.10:11434"
  }
}