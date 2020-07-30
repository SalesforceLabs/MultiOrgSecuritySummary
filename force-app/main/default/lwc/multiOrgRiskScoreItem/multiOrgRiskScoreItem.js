import { LightningElement, api, track } from "lwc";
import { loadScript } from "lightning/platformResourceLoader";

export default class MultiOrgRiskScoreItem extends LightningElement {
  @api risk;
  @api selectedRowId;
  @api riskFilterValues;
  @api itemSize;

  connectedCallback() {
    // console.log('connected');
    //console.log(this.itemSize);
  }

  renderedCallback() {}

  get borderClassName() {
    let borderClassName = "multioss-risk-no-highlight";
    //console.log('INside getBorderClassName');
    //  console.log('Checking this.risk.Id ' + this.risk.Id + ' against ' + this.selectedRowId + ' this.selectedRowId');
    if (this.selectedRowId == this.risk.Id) {
      borderClassName = "multioss-risk-highlight";
    }
    // console.log('Inside getBorderName and returning ' + borderClassName);
    return borderClassName;
  }

  get className() {
    let riskCategoryClass = "multioss-risk-category-" + this.risk.SettingRiskCategory__c;
    let riskType = "multioss-risk-type-" + this.risk.RiskType__c;
    let riskClassName = "multioss-risk " + riskCategoryClass + " " + riskType;
    return riskClassName;
  }

  get boxWidth() {
    //todo AP testing if fixed box sizes are better
    return "width:" + this.itemSize + "px";
  }

  get riskChar() {
    if (this.risk.Change__c == "BETTER") {
      return " "; // '+';
    } else if (this.risk.Change__c == "WORSE") {
      return " "; //'-';
    } else {
      return " ";
    }
  }
}
