import { LightningElement, api } from "lwc";

export default class MultiOrgOrgItem extends LightningElement {
  @api summary = {};
  @api selectedRowId;
  @api selectedOrgId;
  @api riskFilterValues;

  // Sizing
  windowSize;
  @api itemSize;
  @api numberOfRows;

  // State
  @api mode; // byorg | bydate | thisorg
  @api componentState;

  connectedCallback() {
    window.addEventListener("resize", (e) => this.windowResized(e));
  }

  renderedCallback() {
    this.windowResized();
  }

  windowResized(e) {
    let elmnt = this.template.querySelector("div");

    let width = 0;

    if (elmnt !== null && this.numberOfRows !== undefined && this.numberOfRows !== null) {
      width = elmnt.clientWidth;

      if (this.windowSize !== width) {
        this.windowSize = width;
        let tempItemSize = 0;
        if (this.windowSize >= 1400) {
          tempItemSize = (this.windowSize * 0.8) / this.numberOfRows - 5.4;
        } else if (this.windowSize >= 1000) {
          tempItemSize = (this.windowSize * 0.8) / this.numberOfRows - 5.8;
        } else if (this.windowSize >= 800) {
          tempItemSize = (this.windowSize * 0.8) / this.numberOfRows - 6;
        } else {
          tempItemSize = (this.windowSize * 0.8) / this.numberOfRows - 6.3;
        }

        this.itemSize = tempItemSize;
      }
    }
  }

  get doIHaveData() {
    if (this.summary.healthCheck.Score__c === -1) {
      return false;
    }
    return true;
  }

  offset(el) {
    let rect = el.getBoundingClientRect();
    let scrollLeft = window.pageXOffset || document.documentElement.scrollLeft;
    let scrollTop = window.pageYOffset || document.documentElement.scrollTop;

    return { top: rect.top + scrollTop, left: rect.left + scrollLeft };
  }

  showData(event) {
    let selectedRowId = event.currentTarget.dataset.id;
    this.selectedRowId = selectedRowId;
    event.preventDefault();

    let detail = {};
    detail.popupLeft = event.clientX;
    detail.popupTop = event.clientY;

    let thisDiv = this.template.querySelector('[data-id="' + selectedRowId + '"]');
    let divOffset = this.offset(thisDiv);
    detail.popupLeft = divOffset.left;
    detail.popupTop = divOffset.top;
    detail.itemWidth = this.itemSize;

    detail.selectedRowId = selectedRowId;
    detail.orgId = this.summary.healthCheck.Security_Health_Check_Org__c;
    const showDataEvent = new CustomEvent("showdata", { detail: detail });
    this.dispatchEvent(showDataEvent);
  }

  hideData() {
    this.dispatchEvent(new CustomEvent("hidedata"));
  }

  get showByOrg() {
    if (this.mode === "byorg") {
      return true;
    }
    return false;
  }

  get showByDate() {
    return this.mode === "bydate";
  }

  get showThisOrg() {
    return this.mode === "thisorg";
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

  selectSingleOrgSummary(event) {
    let selectedOrgId = event.currentTarget.dataset.id;
    const showOrgSummaryEvent = new CustomEvent("selectsingleorgsummary", {
      detail: selectedOrgId
    });
    this.dispatchEvent(showOrgSummaryEvent);
  }

  selectHealthCheckDetail(event) {
    let selectedHealthCheckId = event.currentTarget.dataset.id;
    const customEvent = new CustomEvent("selecthealthcheckdetail", {
      detail: selectedHealthCheckId
    });
    this.dispatchEvent(customEvent);
  }

  createTaskSelected(event) {
    let selectedOrgId = event.currentTarget.dataset.id;
    let detail = {};
    detail.riskId = "";
    detail.orgId = selectedOrgId;
    const myEvent = new CustomEvent("createtaskselected", { detail: detail });
    this.dispatchEvent(myEvent);
  }

  showDateSummary(event) {
    this.selectedDate = event.currentTarget.dataset.id;

    const showDateSummaryEvent = new CustomEvent("showdatesummary", { detail: this.selectedDate });
    this.dispatchEvent(showDateSummaryEvent);
  }

  get columnClass() {
    return "slds-text-link slds-has-flexi-truncate orgNameCol ";
  }

  get showViewSummaryButton() {
    return this.componentState === "multiOrgSummary";
  }

  get showScore() {
    return this.summary.healthCheck.Score__c >= 0;
  }
}
