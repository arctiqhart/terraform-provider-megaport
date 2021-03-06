// Copyright 2020 Megaport Pty Ltd
//
// Licensed under the Mozilla Public License, Version 2.0 (the
// "License"); you may not use this file except in compliance with
// the License. You may obtain a copy of the License at
//
//       https://mozilla.org/MPL/2.0/
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package resource_megaport

import (
	"errors"
	"github.com/megaport/megaportgo/types"
	"github.com/megaport/megaportgo/vxc"
	"github.com/megaport/terraform-provider-megaport/schema_megaport"
	"github.com/hashicorp/terraform-plugin-sdk/helper/schema"
)

func MegaportAWSConnection() *schema.Resource {
	return &schema.Resource{
		Create: resourceMegaportAWSConnectionCreate,
		Read:   resourceMegaportAWSConnectionRead,
		Update: resourceMegaportAWSConnectionUpdate,
		Delete: resourceMegaportAWSConnectionUpdateDelete,
		Schema: schema_megaport.ResourceAWSConnectionVXCSchema(),
	}
}

func resourceMegaportAWSConnectionCreate(d *schema.ResourceData, m interface{}) error {
	cspSettings := d.Get("csp_settings").(*schema.Set).List()[0].(map[string]interface{})
	vlan := 0

	attachToId := cspSettings["attached_to"].(string)
	partnerPortId := cspSettings["requested_product_id"].(string)
	name := d.Get("vxc_name").(string)
	rateLimit := d.Get("rate_limit").(int)
	hostedConnection := cspSettings["hosted_connection"].(bool)
	connectType := types.CONNECT_TYPE_AWS_VIF
	vifType := cspSettings["visibility"].(string)
	asn := cspSettings["requested_asn"].(int)
	amazonAsn := cspSettings["amazon_asn"].(int)
	ownerAccount := cspSettings["amazon_account"].(string)
	authKey := cspSettings["auth_key"].(string)
	prefixes := cspSettings["prefixes"].(string)
	customerIpAddress := cspSettings["customer_ip"].(string)
	amazonIpAddress := cspSettings["amazon_ip"].(string)

	if aEndConfiguration, ok := d.GetOk("a_end"); ok {
		if newVlan, aOk := aEndConfiguration.(*schema.Set).List()[0].(map[string]interface{})["requested_vlan"].(int); aOk {
			vlan = newVlan
		}
	}

	if hostedConnection {
		connectType = types.CONNECT_TYPE_AWS_HOSTED_CONNECTION
	}

	vxcId, buyErr := vxc.BuyAWSHostedVIF(attachToId, partnerPortId, name, rateLimit, vlan, connectType,
		vifType, asn, amazonAsn, ownerAccount, authKey, prefixes, customerIpAddress, amazonIpAddress)

	if buyErr != nil {
		return buyErr
	}

	d.SetId(vxcId)
	vxc.WaitForVXCProvisioning(vxcId)
	return resourceMegaportAWSConnectionRead(d, m)
}

func resourceMegaportAWSConnectionRead(d *schema.ResourceData, m interface{}) error {
	vxcDetails, retrievalErr := vxc.GetVXCDetails(d.Id())

	if retrievalErr != nil {
		return retrievalErr
	}

	if cspConnection, ok := vxcDetails.Resources.CspConnection.([]interface{}); ok {
		for _, conn := range cspConnection {
			myConn := conn.(map[string]interface{})
			connectType := myConn["connectType"].(string)

			if connectType == "AWS" {
				if _, exists := myConn["vif_id"]; exists {
					d.Set("aws_id", myConn["vif_id"].(string))
				}
			}
		}
	} else if cspConnection, ok := vxcDetails.Resources.CspConnection.(map[string]interface{}); ok {
		connectType := cspConnection["connectType"].(string)

		if connectType == "AWS" {
			if _, exists := cspConnection["vif_id"]; exists {
				d.Set("aws_id", cspConnection["vif_id"].(string))
			}
		}
	} else {
		return errors.New(CannotSetVIFError)
	}

	return ResourceMegaportVXCRead(d, m)
}

func resourceMegaportAWSConnectionUpdate(d *schema.ResourceData, m interface{}) error {
	aVlan := 0

	if aEndConfiguration, ok := d.GetOk("a_end"); ok {
		if newVlan, aOk := aEndConfiguration.(*schema.Set).List()[0].(map[string]interface{})["requested_vlan"].(int); aOk {
			aVlan = newVlan
		}
	}

	cspSettings := d.Get("csp_settings").(*schema.Set).List()[0].(map[string]interface{})
	hostedConnection := cspSettings["hosted_connection"].(bool)

	if d.HasChange("rate_limit") && hostedConnection {
		return errors.New(CannotChangeHostedConnectionRateError)
	}

	if d.HasChange("vxc_name") || d.HasChange("rate_limit") || d.HasChange("a_end") {
		_, updateErr := vxc.UpdateVXC(d.Id(), d.Get("vxc_name").(string),
			d.Get("rate_limit").(int),
			aVlan,
			0)

		if updateErr != nil {
			return updateErr
		}

		vxc.WaitForVXCUpdated(d.Id(), d.Get("vxc_name").(string),
			d.Get("rate_limit").(int),
			aVlan,
			0)
	}

	return resourceMegaportAWSConnectionRead(d, m)
}

func resourceMegaportAWSConnectionUpdateDelete(d *schema.ResourceData, m interface{}) error {
	return ResourceMegaportVXCDelete(d, m)
}
