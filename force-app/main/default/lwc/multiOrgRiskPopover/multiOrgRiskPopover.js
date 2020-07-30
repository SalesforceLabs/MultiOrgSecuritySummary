import { LightningElement, api } from "lwc";

export default class MultiOrgRiskPopover extends LightningElement {
  @api left;
  @api top;
  @api risk;
  @api orgId; // the record id for the security health check org record
  @api windowSize;
  @api itemWidth;

  get boxClass() {
    let tempItemSize = 0;
    if (this.windowSize >= 880) {
      tempItemSize = 90 - this.itemWidth;
    } else {
      tempItemSize = 140 - this.itemWidth;
    }

    let boxclass =
      "width:300px;position:absolute; background-color:white;top:" +
      (this.top - tempItemSize) +
      "px; left:" +
      (this.left - 24) +
      "px";
    if (this.checkFitsToScreen() === false) {
      boxclass =
        "width:300px; background-color:white;top:" +
        (this.top - tempItemSize) +
        "px; left:" +
        (this.left - 280) +
        "px";
    }
    return boxclass;

    //TODO : Fix the rendering so that it flips if the component will be outside of the screen bounds.
  }

  get popoverFooterClass() {
    //mypopover slds-popover slds-nubbin_top-left
    // HIGH_RISK, MEDIUM_RISK, LOW_RISK, INFORMATIONAL

    let footerClass = "";

    if (this.risk.SettingRiskCategory__c === "HIGH_RISK") {
      footerClass = "popoverFooterHigh";
    } else if (this.risk.SettingRiskCategory__c === "MEDIUM_RISK") {
      footerClass = "popoverFooterMedium";
    } else if (this.risk.SettingRiskCategory__c === "LOW_RISK") {
      footerClass = "popoverFooterLow";
    } else {
      footerClass = "popoverFooterInfo";
    }

    return "slds-popover__footer " + footerClass;
  }

  get popoverFooterText() {
    let footerText = "";

    if (this.risk.SettingRiskCategory__c === "HIGH_RISK") {
      footerText = "High-Risk";
    } else if (this.risk.SettingRiskCategory__c === "MEDIUM_RISK") {
      footerText = "Medium-Risk";
    } else if (this.risk.SettingRiskCategory__c === "LOW_RISK") {
      footerText = "Low-Risk";
    } else {
      footerText = "Informational";
    }
    return footerText + " Security Setting";
  }

  get popoverTitleClass() {
    //mypopover slds-popover slds-nubbin_top-left
    // HIGH_RISK, MEDIUM_RISK, LOW_RISK, INFORMATIONAL

    let titleClass = "";

    if (this.risk.RiskType__c === "HIGH_RISK") {
      titleClass = "";
    } else if (this.risk.SettingRiskCategory__c === "MEDIUM_RISK") {
      titleClass = "";
    } else if (this.risk.SettingRiskCategory__c === "LOW_RISK") {
      titleClass = "";
    } else {
      titleClass = "";
    }

    return "";
  }

  get popoverTitleText() {
    // HIGH_RISK, MEDIUM_RISK, MEETS_STANDARD
    let titleText = "";

    if (this.risk.RiskType__c === "HIGH_RISK") {
      titleText = "Critical";
    } else if (this.risk.RiskType__c === "MEDIUM_RISK") {
      titleText = "Warning";
    } else {
      titleText = "Compliant";
    }
    return titleText;
  }

  checkFitsToScreen() {
    if (this.left + 300 - 24 > this.windowSize) {
      return false;
    }

    return true;
  }

  get popoverClass() {
    let titleClass = "slds-popover";
    let sNubbin = "";

    if (this.checkFitsToScreen() === true) {
      sNubbin = "slds-nubbin_top-left";
    } else {
      sNubbin = "slds-nubbin_top-right";
    }
    return "mypopover " + titleClass + " " + sNubbin;
  }

  /* Fire an event to indicate that a create task has been selected for this Risk. */
  createTaskSelected(event) {
    let detail = {};
    detail.riskId = this.risk.Id;
    detail.orgId = this.orgId;
    const myEvent = new CustomEvent("createtaskselected", { detail: detail });
    this.dispatchEvent(myEvent);
  }

  closePopover() {
    const myEvent = new CustomEvent("closepopupselected");
    this.dispatchEvent(myEvent);
  }

  get iconName() {
    let iconName = "utility:success";

    if (this.risk.RiskType__c === "HIGH_RISK") {
      iconName = "utility:error";
    } else if (this.risk.RiskType__c === "MEDIUM_RISK") {
      iconName = "utility:warning";
    }

    return iconName;
  }

  get iconColour() {
    let iconClr = "success";

    if (this.risk.RiskType__c === "HIGH_RISK") {
      iconClr = "error";
    } else if (this.risk.RiskType__c === "MEDIUM_RISK") {
      iconClr = "warning";
    }

    return iconClr;
  }

  get formElementClass() {
    return "slds-form-element slds-form-element_readonly";
  }
}
