import { LightningElement, track } from "lwc";
import getCurrentOrgDetails from "@salesforce/apex/MultiOrgSecuritySummaryService.getCurrentOrgDetails";

export default class MultiOrgSecurityApplication extends LightningElement {
  @track lastUpdatedDate = "2017-12-03T20:00:00.000+00:00";
  @track showEmptyState = false;
  @track showGuide = false;

  // Data
  @track currentOrgDetails = {};

  //Error Handling
  @track error;

  connectedCallback() {
    //this.getOrgDetails();
  }

  getOrgDetails() {
    getCurrentOrgDetails()
      .then((data) => {
        this.currentOrgDetails = data;
        console.log(JSON.stringify(data));
      })
      .catch((error) => {
        this.error = error.message;
      });
  }

  viewGuide() {
    this.showGuide = true;
  }
}
