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
data "megaport_location" "mp_canada_east_mtl" {
  name    = "${var.megaport_location_name_region1}"
  market_code = "${var.megaport_location_marketcode_region1}"
  has_mcr = true
}

// aws partner port
data "megaport_partner_port" "aws_mp_canada_east_mtl" {
  connect_type = "${var.aws_port_company_name}"
  company_name = "${var.aws_port_connect_type}"
  product_name = "${var.aws_megaport_marketplace_name_port_region1}"
  location_id  = data.megaport_location.mp_canada_east_mtl.id
}

// mcr
resource "megaport_mcr" "mp_canada_east_mtl_mcr" {
  mcr_name    = "${var.prefix}.mp_canada_east_mtl"
  location_id = data.megaport_location.mp_canada_east_mtl.id

  router {
    port_speed    = "${var.mcr_port_rate_limit_region1}"
    requested_asn = "${var.mcr_port_asn_region1}"
  }
}

// mcr to aws vxc
resource "megaport_aws_connection" "aws_mp_canada_east_mtl_vxc" {
  vxc_name   = "${var.prefix}-aws_mp_canada_east_mtl"
  rate_limit = "${var.aws_rate_limit_vxc_region1}"

  a_end {
    requested_vlan = 191
  }

  csp_settings {
    attached_to          = megaport_mcr.mp_canada_east_mtl_mcr.id
    requested_product_id = data.megaport_partner_port.aws_mp_canada_east_mtl.id
    requested_asn        = 64550
    amazon_asn           = aws_dx_gateway.megaport_poc.amazon_side_asn
    amazon_account       = data.aws_caller_identity.current.account_id
  }
}

// mcr to gcp vxc
resource "megaport_gcp_connection" "vxc_mp_gcp" {
  vxc_name   = "${var.prefix}-vxc-mp-gcp"
  rate_limit = "${var.mcr_vxc_rate_limit_region1}"

  a_end {
    requested_vlan = 182
  }

  csp_settings {
    attached_to = megaport_mcr.vxc_mp_gcp.id
    pairing_key = google_compute_interconnect_attachment.megaport_poc.pairing_key
  }
}