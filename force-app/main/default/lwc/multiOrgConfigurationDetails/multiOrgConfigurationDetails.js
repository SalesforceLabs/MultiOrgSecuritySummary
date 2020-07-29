/**
 * Multi org configuration details is a modal that is used to display the org settings of the org that you are
 * currently viewing from.
 */

import { LightningElement, api } from "lwc";

export default class MultiOrgConfigurationDetails extends LightningElement {
  @api orgConfiguration = [];

  navigateToOrg(event) {
    let recordId = event.currentTarget.dataset.id;
    const customEvent = new CustomEvent("navigatetoorgdetails", { detail: recordId });
    this.dispatchEvent(customEvent);
    this.closeModal();
  }

  closeModal() {
    const customEvent = new CustomEvent("closeorgconfigurationmodal");
    this.dispatchEvent(customEvent);
  }

  manageSync() {
    const customEvent = new CustomEvent("managesync");
    this.dispatchEvent(customEvent);
    this.closeModal();
  }
}
