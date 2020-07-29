/**
 * the create task modal is used to ensure users can create a Security Task from the UI.
 */

import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class MultiOrgCreateTask extends LightningElement {
  @api riskId;
  @api orgId;

  handleClose() {
    const myEvent = new CustomEvent("closecreatetask");
    this.dispatchEvent(myEvent);
  }

  handleSuccess(event) {
    // const payload = event.detail;
    //  console.log(JSON.stringify(payload));
    const myToast = new ShowToastEvent({
      title: "Success",
      message: "The Security Task has been created.",
      variant: "success"
    });
    this.dispatchEvent(myToast);
    this.handleClose();
  }
}
