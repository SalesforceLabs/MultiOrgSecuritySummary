import { LightningElement, api, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import runFirstSecurityJob from "@salesforce/apex/MultiOrgSecuritySummarySetupUtilities.runFirstSecurityJob";
import checkFirstSecurityJobStatus from "@salesforce/apex/MultiOrgSecuritySummarySetupUtilities.checkFirstSecurityJobStatus";
import getCurrentSecurityScheduleCron from "@salesforce/apex/MultiOrgSecuritySummarySetupUtilities.getCurrentSecurityScheduleCron";
import scheduleSecuritySync from "@salesforce/apex/MultiOrgSecuritySummarySetupUtilities.scheduleSecuritySync";
import deleteScheduledJob from "@salesforce/apex/MultiOrgSecuritySummarySetupUtilities.deleteScheduledJob";
import getCurrentDateTime from "@salesforce/apex/MultiOrgSecuritySummarySetupUtilities.getCurrentDateTime";

export default class MultiOrgSummaryScheduler extends LightningElement {
  @api orgConfiguration = {};
  syncScheduled;
  firstJobSubmitted;
  firstJobStatus;
  currentCron;
  @track currentCronInTime;
  showSecuritySyncModal;
  syncStatusLoading;
  state = "completed"; // first, schedule, completed
  error;

  // Message Properties
  @track showMessage;
  @track messageTitle;
  @track messageBody;
  @track messageVariant;
  @track messageStatus;
  @track dateTimeSubmitted;

  connectedCallback() {
    this.getCurrentSecurityScheduleCron();
    this.getCurrentDateTime();
  }

  getCurrentSecurityScheduleCron() {
    getCurrentSecurityScheduleCron({})
      .then((data) => {
        console.log(data);

        if (data === "schedule") {
          this.state = "schedule";
          this.syncScheduled = false;
          this.stopLoading(500);
        } else if (data === "first") {
          this.state = "first";
          this.syncScheduled = false;
          this.stopLoading(500);
        } else if (data !== null) {
          let convertedCron = data.split(" ");
          this.currentCronInTime = convertedCron[2] + ":" + convertedCron[1] + ":00.000";
          this.currentCron = data;
          this.syncScheduled = true;
          this.state = "completed";
          this.stopLoading(500);
        }
      })
      .catch((error) => {
        this.stopLoading(500);
        this.showUIMessage("Error", error.message, "error", "utility:error", "inverse");
      });
  }

  runFirstSecurityJob() {
    this.hideUIMessage();
    this.syncStatusLoading = true;
    runFirstSecurityJob({})
      .then((data) => {
        this.checkFirstSecurityJobStatus();
        console.log(data);
        this.firstJobSubmitted = data;
      })
      .catch((error) => {
        this.stopLoading(100);
        this.showUIMessage("Error", error.message, "error", "utility:error", "inverse");
      });
  }

  getCurrentDateTime() {
    getCurrentDateTime({})
      .then((data) => {
        console.log(data);

        this.dateTimeSubmitted = data;
      })
      .catch((error) => {
        console.log("Unable to get Date/time");
      });
  }

  checkFirstSecurityJobStatus() {
    //this.hideUIMessage();
    checkFirstSecurityJobStatus({ submittedDatetime: this.dateTimeSubmitted })
      .then((data) => {
        if (data) {
          let status = data.Status;
          console.log("Checking Status: " + status);

          let parentOrg = this.orgConfiguration.OrgConfiguration.multioss__Is_this_the_Central_org__c;

          if (status === "Aborted" || status === "Completed" || status === "Failed") {
            console.log("Aborted Completed or Failed: " + status);
            if (status === "Completed" || parentOrg === true) {
              console.log("First Job Completed");
              this.state = "schedule";
              this.stopLoading(100);
              this.showUIToast("Success", "The Sync has Completed", "success");
              this.firstJobStatus = data;
              console.log("First Job Completed");
            } else if (parentOrg === true) {
              console.log("Not Completed or Parent");
              this.stopLoading(100);
              this.showUIMessage(data.Status, data.ExtendedStatus, "error", "utility:error", "inverse");
              this.firstJobStatus = data;
            } else {
              console.log("Aborted or Failed");
              this.stopLoading(100);
              this.showUIMessage(data.Status, data.ExtendedStatus, "error", "utility:error", "inverse");
              this.firstJobStatus = data;
            }
          } else {
            console.log("Trying Again: " + status);
            setTimeout(() => {
              console.log("Checking");
              this.checkFirstSecurityJobStatus();
            }, 100);
          }
        } else {
          console.log("Trying Again: " + status);
          setTimeout(() => {
            console.log("Checking");
            this.checkFirstSecurityJobStatus();
          }, 100);
        }
      })
      .catch((error) => {
        this.showUIMessage("Error", error.message, "error", "utility:error", "inverse");
        this.syncStatusLoading = true;
      });
  }

  scheduleSecuritySync() {
    this.hideUIMessage();
    this.syncStatusLoading = true;
    scheduleSecuritySync({ cronString: this.currentCron })
      .then((data) => {
        console.log(data);

        if (data === true) {
          this.state = "completed";
          this.showUIToast("Success", "The Sync has been scheduled", "success");
          this.getCurrentSecurityScheduleCron();
          this.syncScheduled = true;
        } else {
          this.syncScheduled = false;
          this.stopLoading(100);
          this.showUIMessage("Error", "Unable to schedule sync", "error", "utility:error", "inverse");
        }
      })
      .catch((error) => {
        this.stopLoading(100);
        this.showUIMessage("Error", error.message, "error", "utility:error", "inverse");
      });
  }

  deleteScheduledJob() {
    this.hideUIMessage();
    this.syncStatusLoading = true;
    deleteScheduledJob({})
      .then((data) => {
        console.log(data);

        if (data === true) {
          this.state = "schedule";
          this.syncScheduled = false;
          this.currentCronInTime = "";
          this.showUIToast("Success", "The Sync has been canceled", "success");
          this.stopLoading(100);
        } else {
          this.stopLoading(100);
          this.showUIMessage("Error", "We were unable to cancel the Sync", "error", "utility:error", "inverse");
        }
      })
      .catch((error) => {
        this.stopLoading(100);
        this.showUIMessage("Error", error.message, "error", "utility:error", "inverse");
      });
  }

  handleTimeChange(event) {
    console.log(event.target.value);

    let time = event.target.value;

    //17:45:00.000

    let convertedTime = time.split(":");

    console.log(convertedTime);

    let cron = "0 " + convertedTime[1] + " " + convertedTime[0] + " ? * * *";

    console.log(cron);

    this.currentCron = cron;
  }

  get showAlertBanner() {
    if (this.currentCron === null) {
      return true;
    }
  }

  @api
  openSyncSchedule() {
    this.showSecuritySyncModal = true;
  }

  closeModal() {
    this.showSecuritySyncModal = false;
  }

  stopLoading(timeoutValue) {
    setTimeout(() => {
      this.syncStatusLoading = false;
    }, timeoutValue);
  }

  showUIMessage(title, message, variant, icon, iconVariant) {
    this.messageTitle = title;
    this.messageBody = message;
    this.messageVariant = variant;
    this.messageIcon = icon;
    this.messageIconVariant = iconVariant;
    this.showMessage = true;
  }

  showUIToast(title, message, variant) {
    const event = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant
    });
    this.dispatchEvent(event);
  }

  hideUIMessage() {
    this.messageTitle;
    this.messageBody;
    this.messageVariant;
    this.messageIcon;
    this.messageIconVariant;
    this.showMessage = false;
  }

  get uiMessageVariantCSS() {
    switch (this.messageVariant) {
      case "success":
        return "slds-box slds-m-bottom--medium slds-theme_success slds-theme_alert-texture";
      case "error":
        return "slds-box slds-m-bottom--medium slds-theme_error slds-theme_alert-texture";
      case "warning":
        return "slds-box slds-m-bottom--medium slds-theme_warning slds-theme_alert-texture";
      case "info":
        return "slds-box slds-m-bottom--medium slds-theme_info slds-theme_alert-texture";
      default:
        this.error = "error";
    }
  }

  get scheduleState() {
    return this.state === "schedule";
  }

  get firstState() {
    return this.state === "first";
  }

  get completedState() {
    return this.state === "completed";
  }

  get firstOrScheduleState() {
    return this.state === "first" || this.state === "schedule";
  }
}
