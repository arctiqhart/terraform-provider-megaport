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

// megaport locations used for ports and mcr
data "megaport_location" "nextdc_b1" {
  name    = "NextDC B1"
  has_mcr = true
}

data "megaport_location" "gs_syd" {
  name = "Global Switch Sydney West"
}

// aws partner port
data "megaport_partner_port" "aws_syd_port" {
  connect_type = "AWS"
  company_name = "AWS"
  product_name = "Asia Pacific (Sydney) (ap-southeast-2)"
  location_id  = data.megaport_location.gs_syd.id
}

// mcr
resource "megaport_mcr" "example" {
  mcr_name    = "${var.prefix} Terraform Test - MCR"
  location_id = data.megaport_location.nextdc_b1.id

  router {
    port_speed    = 5000
    requested_asn = 64555
  }
}

// mcr to aws vxc
resource "megaport_aws_connection" "example" {
  vxc_name   = "${var.prefix}-vxc-mp-aws"
  rate_limit = 1000

  a_end {
    requested_vlan = 191
  }

  csp_settings {
    attached_to          = megaport_mcr.example.id
    requested_product_id = data.megaport_partner_port.aws_syd_port.id
    requested_asn        = 64550
    amazon_asn           = aws_dx_gateway.megaport_poc.amazon_side_asn
    amazon_account       = data.aws_caller_identity.current.account_id
  }
}

// mcr to gcp vxc
resource "megaport_gcp_connection" "vxc_mp_gcp" {
  vxc_name   = "${var.prefix}-vxc-mp-gcp"
  rate_limit = 1000

  a_end {
    requested_vlan = 182
  }

  csp_settings {
    attached_to = megaport_mcr.vxc_mp_gcp.id
    pairing_key = google_compute_interconnect_attachment.megaport_poc.pairing_key
  }
}
