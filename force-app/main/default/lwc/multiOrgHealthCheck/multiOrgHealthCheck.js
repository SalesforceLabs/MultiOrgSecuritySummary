import { LightningElement, track, api } from "lwc";

const healthCheckActions = [
  { label: "Show Details", name: "showDetails" },
  { label: "Create Task", name: "createTask" }
];

const healthCheckColumns = [
  {
    label: "Status",
    fieldName: "RiskType__c",
    initialWidth: 150,
    cellAttributes: { class: { fieldName: "riskColor" } }
  },
  { label: "Setting", fieldName: "Setting__c", initialWidth: 300, wrapText: true },
  { label: "Your Value", fieldName: "OrgValue__c" },
  { label: "Standard Value", fieldName: "StandardValue__c" },
  {
    type: "action",
    typeAttributes: { rowActions: healthCheckActions }
  }
];

export default class MultiOrgHealthCheck extends LightningElement {
  @api singleHealthCheck = [];
  @api singleHealthCheckDate;
  @api orgId;
  healthCheckColumns = healthCheckColumns;
  error;

  handleRowAction(event) {
    let actionName = event.detail.action.name;
    switch (actionName) {
      case "showDetails":
        console.log("try and show details" + JSON.stringify(event.detail.row));
        this.showDetails(event.detail.row.Id);
        break;
      case "createTask":
        this.createTaskSelected(event);
        break;
      default:
        this.error = "error";
    }
  }

  showDetails(event) {
    let riskId = event.currentTarget.dataset.id;
    const myEvent = new CustomEvent("selectriskdetailmodal", { detail: riskId });
    this.dispatchEvent(myEvent);
  }

  createTaskSelected(event) {
    let riskId = event.currentTarget.dataset.id;
    let detail = {};
    detail.riskId = riskId;
    detail.orgId = this.orgId;
    const customEvent = new CustomEvent("createtaskselected", { detail: detail });
    this.dispatchEvent(customEvent);
  }
}
