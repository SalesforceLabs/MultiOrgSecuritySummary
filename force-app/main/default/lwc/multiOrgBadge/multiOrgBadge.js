/**
 * The badge component is used to display the security score in the context of a color on the security org org row.
 */

import { LightningElement, api } from "lwc";

export default class MultiOrgBadge extends LightningElement {
  @api score;

  get scoreText() {
    let scoreText = "";

    if (this.score > 89) {
      scoreText = "Excellent";
    } else if (this.score > 79) {
      scoreText = "Very Good";
    } else if (this.score > 69) {
      scoreText = "Good";
    } else if (this.score > 54) {
      scoreText = "Poor";
    } else {
      scoreText = "Very Poor";
    }
    return scoreText;
  }

  get scoreClass() {
    let scoreClass = "";
    if (this.score > 66) {
      scoreClass = "multioss-badge-green";
    } else if (this.score > 34) {
      scoreClass = "multioss-badge-orange";
    } else if (this.score > 0) {
      scoreClass = "multioss-badge-red";
    } else {
      scoreClass = "multioss-badge-gray";
    }
    return "slds-float_left slds-m-right_xx-small multioss-badge " + scoreClass;
  }
}
