import { LightningElement, api, track } from "lwc";

export default class MultiOrgHeaderRow extends LightningElement {
  @api summaryCategories;
  @track highRiskCount;
  @track mediumRiskCount;
  @track lowRiskCount;
  @track informationalRiskCount;

  @api totalWidth;
  @api itemSize;

  @track standardPadding = 10;

  connectedCallback() {
    console.log("Header Row Loaded");
    this.processHeader();
  }

  processHeader() {
    /* loop through the summaries and calculate widths, etc */
    try {
      for (let categoryNameIndex in this.summaryCategories) {
        let categoryGroup = this.summaryCategories[categoryNameIndex];

        console.log("categoryGroup is ", JSON.stringify(categoryGroup));

        console.log("categoryNameIndex is " + categoryNameIndex);
        switch (categoryNameIndex) {
          case "HIGH_RISK":
            console.log("Setting highRiskCount to  " + categoryGroup.length);
            this.highRiskCount = categoryGroup.length;
            break;

          case "MEDIUM_RISK":
            this.mediumRiskCount = categoryGroup.length;
            break;

          case "LOW_RISK":
            this.lowRiskCount = categoryGroup.length;

            break;

          default:
            this.informationalRiskCount = categoryGroup.length;
        }
      }
    } catch (e) {
      console.log("Unable to find categories ");
    }
  }
  get highRiskStyle() {
    console.log("high is " + this.highRiskCount * (this.itemSize + this.standardPadding));
    let width = Math.round(this.highRiskCount * (this.itemSize + this.standardPadding));
    return "width:" + width + "px; background-color:red";
  }

  get mediumRiskStyle() {
    console.log("medium is " + this.mediumRiskCount * (this.itemSize + this.standardPadding));
    let width = Math.round(this.mediumRiskCount * (this.itemSize + this.standardPadding));
    return "width:" + width + "px; background-color:orange";
  }

  get lowRiskStyle() {
    console.log("low is " + this.lowRiskCount * (this.itemSize + this.standardPadding));
    let width = Math.round(this.lowRiskCount * (this.itemSize + this.standardPadding));
    return "width:" + width + "px; background-color:green";
  }

  get informationalRiskStyle() {
    console.log("info is " + this.informationalRiskCount * (this.itemSize + this.standardPadding));
    let width = Math.round(this.informationalRiskCount * (this.itemSize + this.standardPadding));
    return "width:" + width + "px; background-color:gray";
  }
}
