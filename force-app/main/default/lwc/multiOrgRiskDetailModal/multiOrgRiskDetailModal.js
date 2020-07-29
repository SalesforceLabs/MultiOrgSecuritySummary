/**
 * Created by stephan.garcia on 2020-04-26.
 */

import { LightningElement, api } from "lwc";

export default class MultiOrgRiskDetailModal extends LightningElement {
  @api risk;
  @api orgId; // the record id for the security health check org record

  createTaskSelected(event) {
    let detail = {};
    detail.riskId = this.risk.Id;
    detail.orgId = this.orgId;
    const customEvent = new CustomEvent("createtaskselected", { detail: detail });
    this.dispatchEvent(customEvent);
    this.closeModal();
  }

  closeModal() {
    console.log("Inside closePopover");
    const customEvent = new CustomEvent("closeriskdetailmodal");
    this.dispatchEvent(customEvent);
  }
}
