import { LightningElement, api, track } from "lwc";

import Current_Security_Status from "@salesforce/label/c.Current_Security_Status";
import Multi_Org_Heading_Body from "@salesforce/label/c.Multi_Org_Heading_Body";
import Multi_Org_Statistics_Title from "@salesforce/label/c.Multi_Org_Statistics_Title";
import Multi_Org_Statistics_Production from "@salesforce/label/c.Multi_Org_Statistics_Production";
import Multi_Org_Statistics_Sandbox from "@salesforce/label/c.Multi_Org_Statistics_Sandbox";
import Multi_Org_Statistics_Average from "@salesforce/label/c.Multi_Org_Statistics_Average";
import Multi_Org_Statistics_Tasks from "@salesforce/label/c.Multi_Org_Statistics_Tasks";
import Single_Org_Details_Title from "@salesforce/label/c.Single_Org_Details_Title";
import Single_Org_Details_Org_Id from "@salesforce/label/c.Single_Org_Details_Org_Id";
import Single_Org_Details_Category from "@salesforce/label/c.Single_Org_Details_Category";
import Single_Org_Details_Classification from "@salesforce/label/c.Single_Org_Details_Classification";
import Single_Org_Details_Admin from "@salesforce/label/c.Single_Org_Details_Admin";
import Single_Org_Statistics_Score from "@salesforce/label/c.Single_Org_Statistics_Score";
import Single_Org_Statistics_Days_Ago from "@salesforce/label/c.Single_Org_Statistics_Days_Ago";
import Single_Org_Statistics_Org_Not_Synced from "@salesforce/label/c.Single_Org_Statistics_Org_Not_Synced";
import Single_Org_Statistics_Open_Tasks from "@salesforce/label/c.Single_Org_Statistics_Open_Tasks";
import Child_Org_Sync_Status from "@salesforce/label/c.Child_Org_Sync_Status";
import Child_Org_Last_Updated from "@salesforce/label/c.Child_Org_Last_Updated";
import Multi_Org_Daily_Security_Summary_Title from "@salesforce/label/c.Multi_Org_Daily_Security_Summary_Title";
import Multi_Org_Daily_Security_Summary_Description from "@salesforce/label/c.Multi_Org_Daily_Security_Summary_Description";
import Child_Org_Status_Last_Updated from "@salesforce/label/c.Child_Org_Status_Last_Updated";
import Multi_Org_Statistics_Average_Helptext from "@salesforce/label/c.Multi_Org_Statistics_Average_Helptext";

export default class MultiOrgDetailHeading extends LightningElement {
  label = {
    Current_Security_Status,
    Multi_Org_Heading_Body,
    Multi_Org_Statistics_Title,
    Multi_Org_Statistics_Production,
    Multi_Org_Statistics_Sandbox,
    Multi_Org_Statistics_Tasks,
    Single_Org_Details_Title,
    Single_Org_Details_Org_Id,
    Single_Org_Details_Category,
    Single_Org_Details_Classification,
    Single_Org_Details_Admin,
    Multi_Org_Statistics_Average,
    Single_Org_Statistics_Score,
    Single_Org_Statistics_Org_Not_Synced,
    Single_Org_Statistics_Days_Ago,
    Single_Org_Statistics_Open_Tasks,
    Child_Org_Sync_Status,
    Child_Org_Last_Updated,
    Multi_Org_Daily_Security_Summary_Title,
    Multi_Org_Daily_Security_Summary_Description,
    Child_Org_Status_Last_Updated,
    Multi_Org_Statistics_Average_Helptext
  };

  @api currentOrgDetails = {};
  @api numberOfTasks = 0;
  @api orgConfiguration = {};
  @api componentState;

  get showMultiOrgOverview() {
    return this.componentState === "overview-heading";
  }

  get multiOrgSummaryState() {
    return this.componentState === "multiOrgSummary";
  }

  get singleOrgSummaryState() {
    return this.componentState === "singleOrgSummary";
  }

  get childOrgSummaryState() {
    return this.componentState === "childOrgSummary";
  }

  get singleAndChildOrgSummaryState() {
    return this.componentState === "childOrgSummary" || this.componentState === "singleOrgSummary";
  }

  get multiAndChildSummaryState() {
    return this.componentState === "childOrgSummary" || this.componentState === "multiOrgSummary";
  }

  get currentDateSet() {
    return this.currentOrgDetails.LatestHealthCheckDate !== null;
  }

  get openSecurityTaskStyle() {
    let totalTasks = this.numberOfTasks;

    console.log("total tasks: " + totalTasks);

    if (totalTasks === 0) {
      return "slds-text-heading--small multioss-callout-number slds-text-align--center multioss-success-text";
    } else if (totalTasks <= 5) {
      return "slds-text-heading--small multioss-callout-number slds-text-align--center multioss-warning-text";
    } else if (totalTasks >= 6) {
      return "slds-text-heading--small multioss-callout-number slds-text-align--center multioss-error-text";
    } else {
      return "slds-text-heading--small multioss-callout-number slds-text-align--center";
    }
  }

  get totalSecurityScoreStyle() {
    let latestHealthCheckScore = this.currentOrgDetails.LatestHealthCheckScore;

    /*   90% and above = Excellent
             80%–89% = Very Good
             70%–79% = Good
             55%–69% = Poor
             54% and below = Very Poor */

    if (latestHealthCheckScore >= 80) {
      return "slds-text-heading--small multioss-callout-number slds-text-align--center multioss-success-text";
    } else if (latestHealthCheckScore >= 60) {
      return "slds-text-heading--small multioss-callout-number slds-text-align--center multioss-warning-text";
    } else if (latestHealthCheckScore < 60) {
      return "slds-text-heading--small multioss-callout-number slds-text-align--center multioss-error-text";
    } else {
      return "slds-text-heading--small multioss-callout-number slds-text-align--center";
    }
  }
}
