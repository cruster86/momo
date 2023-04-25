##############    Create DNS Zone & Records    ##############

resource "yandex_dns_zone" "my-zone" {
  name        = "my-public-zone"
  description = "momo-store"

  labels = {
    label1 = "momo-store"
  }

  zone    = "momo-store.corpsehead.space."
  public  = true
}

resource "yandex_dns_recordset" "rs1" {
  zone_id = yandex_dns_zone.my-zone.id
  name    = "momo-store.corpsehead.space."
  type    = "A"
  ttl     = 300
  data    = ["${yandex_kubernetes_cluster.k8s-corpsehead.master.0.external_v4_address}"]
}
