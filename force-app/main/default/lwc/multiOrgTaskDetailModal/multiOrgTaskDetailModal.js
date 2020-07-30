import { LightningElement, api, track, wire } from "lwc";
import getTaskDetails from "@salesforce/apex/MultiOrgSecuritySummaryService.getTaskDetails";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { updateRecord } from "lightning/uiRecordApi";
import ID_FIELD from "@salesforce/schema/Security_Health_Check_Task__c.Id";
import STATUS_FIELD from "@salesforce/schema/Security_Health_Check_Task__c.Status__c";
import RESOLUTION_FIELD from "@salesforce/schema/Security_Health_Check_Task__c.Resolution__c";

export default class MultiOrgTaskDetailModal extends LightningElement {
  @api taskId;
  @track riskId;
  taskDetailState = "view"; // view or edit
  taskDetails;
  @track loading;
  updatedStatus;
  updatedResolution;
  @track statusOptions;

  connectedCallback() {
    this.loading = true;
    this.getTasks();
  }

  getTasks() {
    getTaskDetails({ taskId: this.taskId })
      .then((data) => {
        this.taskDetails = data;
        console.log("Task Data: " + JSON.stringify(data));
        this.loading = false;
      })
      .catch((error) => {
        console.log(error.message);
      });
  }

  closeModal() {
    console.log("Inside closePopover");
    const customEvent = new CustomEvent("closetaskdetail");
    this.dispatchEvent(customEvent);
  }

  get caseStatusOptions() {
    return [
      { label: "In Progress", value: "In Progress" },
      { label: "Completed", value: "Completed" },
      { label: "Canceled", value: "Canceled" }
    ];
  }

  get showViewState() {
    return this.taskDetailState === "view";
  }

  get showUpdateState() {
    return this.taskDetailState === "update";
  }

  updateTask() {
    this.taskDetailState = "update";
    this.loading = true;
    this.stopLoading(500);
  }

  handleStatusChange(event) {
    this.updatedStatus = event.target.value;
  }

  handleResolutionChange(event) {
    this.updatedResolution = event.target.value;
  }

  saveTask() {
    this.loading = true;
    const fields = {};
    fields[ID_FIELD.fieldApiName] = this.taskId;
    fields[STATUS_FIELD.fieldApiName] = this.updatedStatus;
    fields[RESOLUTION_FIELD.fieldApiName] = this.updatedResolution;
    const recordInput = { fields };
    updateRecord(recordInput)
      .then((data) => {
        console.log(JSON.stringify(data));
        this.closeModal();
        this.stopLoading(10);
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Success",
            message: "Security Task Updated",
            variant: "success"
          })
        );
      })
      .catch((error) => {
        console.log(JSON.stringify(error));
      });
  }

  cancelUpdate() {
    this.taskDetailState = "view";
    this.loading = true;
    this.stopLoading(500);
  }

  stopLoading(timeoutValue) {
    setTimeout(() => {
      this.loading = false;
    }, timeoutValue);
  }

  get showRelatedRecords() {
    return (
      this.taskDetails.Related_To_Risk__r !== null || this.taskDetails.Related_To_Org__r !== null
    );
  }
}
