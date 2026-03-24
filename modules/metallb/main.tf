resource "kubernetes_manifest" "ipaddresspool_metallb_system_first_pool" {
  manifest = {
    "apiVersion" = "metallb.io/v1beta1"
    "kind" = "IPAddressPool"
    "metadata" = {
      "name" = "first-pool"
      "namespace" = "metallb-system"
    }
    "spec" = {
      "addresses" = [
        "10.206.100.0-10.206.110.255",
      ]
    }
  }
}

resource "kubernetes_manifest" "bgppeer" {
  manifest = {
    "apiVersion" = "metallb.io/v1beta1"
    "kind" = "BGPPeer"
    "metadata" = {
      "name" = "bgppeer-10.206.0.1"
      "namespace" = "metallb-system"
    }
    "spec" = {
      "myASN" = 64500
      "peerASN" = 64499
      "peerAddress" = "10.206.0.1"
    }
  }
}

resource "kubernetes_manifest" "bgpadvertisement" {
  manifest = {
    "apiVersion" = "metallb.io/v1beta1"
    "kind" = "BGPAdvertisement"
    "metadata" = {
      "name" = "bgp-advertisement"
      "namespace" = "metallb-system"
    }
    "spec" = {
      "aggregationLength" = 32
      "ipAddressPools" = [
        "first-pool"
      ]
      "localPref" = 100
    }
  }
}
