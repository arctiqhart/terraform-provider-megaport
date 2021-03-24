/**
 * Copyright 2020 Megaport Pty Ltd
 *
 * Licensed under the Mozilla Public License, Version 2.0 (the
 * "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 *
 *       https://mozilla.org/MPL/2.0/
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

data "google_compute_zones" "available" {
  region = google_compute_subnetwork.megaport_poc.region
}

// networking
resource "google_compute_network" "megaport_poc" {
  name                    = "${lower(var.prefix)}-network"
  auto_create_subnetworks = false
}

resource "google_compute_firewall" "megaport_poc" {
  name    = "${lower(var.prefix)}-firewall"
  network = google_compute_network.megaport_poc.self_link

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  allow {
    protocol = "icmp"
  }
}

resource "google_compute_subnetwork" "megaport_poc" {
  name          = "${lower(var.prefix)}-subnetwork"
  ip_cidr_range = var.gcp_subnetwork_cidr
  region        = var.gcp_region
  network       = google_compute_network.megaport_poc.self_link
}

// interconnect setup
resource "google_compute_router" "megaport_poc" {
  name    = "${lower(var.prefix)}-router"
  network = google_compute_network.megaport_poc.name

  bgp {
    asn            = var.gcp_router_asn
    advertise_mode = "CUSTOM"

    advertised_ip_ranges {
      range = google_compute_subnetwork.megaport_poc.ip_cidr_range
    }
  }
}

resource "google_compute_interconnect_attachment" "megaport_poc" {
  name                     = "${lower(var.prefix)}-interconnect"
  type                     = "PARTNER"
  router                   = google_compute_router.megaport_poc.self_link
  edge_availability_domain = "AVAILABILITY_DOMAIN_1"
}


// instance
resource "google_compute_instance" "megaport_poc" {
  name                      = "${lower(var.prefix)}-instance"
  machine_type              = var.gcp_machine_type
  zone                      = data.google_compute_zones.available.names[0]
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  scratch_disk {
    interface = "SCSI"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.megaport_poc.self_link

    access_config {
      // ephemeral ip
    }
  }

  service_account {
    scopes = ["userinfo-email", "cloud-platform"]
  }
}
