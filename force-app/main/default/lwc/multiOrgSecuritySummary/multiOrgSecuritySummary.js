/**
 * https://help.salesforce.com/articleView?id=security_health_check_score.htm&type=5

 90% and above = Excellent
 80%–89% = Very Good
 70%–79% = Good
 55%–69% = Poor
 54% and below = Very Poor

 Recommended Actions Based on Your Score
 IF YOUR TOTAL SCORE IS...	WE RECOMMEND TO...
 0%–33%	Remediate high risks immediately
 34%–66% Remediate high risks in the short term, and medium risks in the long term
 67%–100% Review Health Check periodically to remediate risks

 */
import { LightningElement, track, wire, api } from "lwc";

import getSummaries from "@salesforce/apex/MultiOrgSecuritySummaryService.getSummaries";
import getCurrentOrgDetails from "@salesforce/apex/MultiOrgSecuritySummaryService.getCurrentOrgDetails";
import getCurrentOrgConfigurationDetails from "@salesforce/apex/MultiOrgSecuritySummaryService.getCurrentOrgConfigurationDetails";
import getSecurityHealthCheckTasks from "@salesforce/apex/MultiOrgSecuritySummaryService.getSecurityHealthCheckTasks";
import getSecurityAdminDetails from "@salesforce/apex/MultiOrgSecuritySummaryService.getSecurityAdminDetails";
import courseImages from "@salesforce/resourceUrl/courseImages";

// Navigation
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { updateRecord } from "lightning/uiRecordApi";
import ID_FIELD from "@salesforce/schema/Security_Health_Check_Task__c.Id";
import STATUS_FIELD from "@salesforce/schema/Security_Health_Check_Task__c.Status__c";

const securityTaskActions = [
  { label: "Show Details", name: "showDetails" },
  { label: "Mark Completed", name: "markCompleted" }
];

const securityTaskColumns = [
  { label: "Task", fieldName: "Title__c" },
  { label: "Severity", fieldName: "Severity__c" },
  { label: "Status", fieldName: "Status__c" },
  { label: "Assigned to", fieldName: "Assigned_Name__c" },
  { label: "Due Date", fieldName: "Due_Date__c", type: "date-local" },
  {
    type: "action",
    typeAttributes: { rowActions: securityTaskActions }
  }
];

// Custom Labels

import Child_Org_Overview from "@salesforce/label/c.Child_Org_Overview";
import Multi_Org_Overview from "@salesforce/label/c.Multi_Org_Overview";
import Multi_Org_Security_Summary from "@salesforce/label/c.Multi_Org_Security_Summary";
import New_Security_Task from "@salesforce/label/c.New_Security_Task";
import View_Configuration from "@salesforce/label/c.View_Configuration";
import View_User_Guide from "@salesforce/label/c.View_User_Guide";

const DELAY = 350;

export default class MultiOrgSecuritySummary extends NavigationMixin(LightningElement) {
  label = {
    Child_Org_Overview,
    Multi_Org_Overview,
    Multi_Org_Security_Summary,
    New_Security_Task,
    View_User_Guide,
    View_Configuration
  };

  // NOT USED
  @track summaryCategories;

  // Data
  @track orgConfiguration = [];
  @track summaries = [];
  @track currentTasks = [];
  @track securityAdmin = [];

  // Selected Data
  @track selectedRisk;
  @track selectedRowId;
  @track selectedOrgId;
  @track singleHealthCheck = {};
  @track singleHealthCheckSelected = false;
  @track singleHealthCheckDate = "";
  @track selectedIndex = 0;
  @track selectedOrgData = {};
  selectedTaskId;

  // Filter Options
  @track maxRows = 30;
  @track daysSinceFirstHealthCheck = 30;
  @track filterValue = ["HIGH_RISK", "MEDIUM_RISK", "MEETS_STANDARD"];
  @track selectedDate;
  @track currentDate;
  @track filterOrgValue = ["Excellent", "Good", "Poor"];

  @track orgSortOrder = "alpha"; // score

  // Task Variables
  @track taskRiskId;
  @track taskOrgId;

  // Sizing Utilities
  @track numberOfRows = 37; // Default Value is 37
  @track windowSize = 1000; // Default Value is 1000
  itemWidth = 0;

  // Data Table Configuration
  securityTaskColumns = securityTaskColumns;

  // State
  @track mode; // bydate | byorg
  tabState = "overview"; // overview, details, tabs, admin
  componentState; // multiOrgSummary, singleOrgSummary, childOrgSummary

  //Loading
  parentLoading = true;
  childLoading = false;
  healthCheckDetailsLoading = false;

  // PopOver Utilities
  @track showPopup;
  @track hidePopup;
  @track popupLeft;
  @track popupTop;

  //Static Resources
  @track baseStaticResourceURL = courseImages + "/";

  // Modals
  showOrgConfigurationModal = false;
  showRiskDetailModal = false;
  showCreateTaskModal = false;
  showTaskDetailModal = false;
  showGuideModal = false;

  connectedCallback() {
    this.mode = "bydate";
    this.updateState("component", "multiOrgSummary");
    this.getConfiguration();
    window.addEventListener("resize", (e) => this.windowResized(e));
  }

  renderedCallback() {
    this.windowResized();
  }

  // Get the app configuration details
  getConfiguration() {
    getCurrentOrgConfigurationDetails({})
      .then((data) => {
        if (data === null) {
          this.updateState("component", "notSetup");
          this.mode === "";
          this.showGuideModal = true;
          this.stopLoading(100);
        } else {
          this.orgConfiguration = data;
          this.selectedDate = data.LocalDate;
          this.currentDate = data.LocalDate;
          // Get the summary data once the config has loaded
          this.getTheSummaries();
        }
      })
      .catch((error) => {});
  }

  // Sizing Utilities
  windowResized(e) {
    let elmnt = this.template.querySelector("div");
    let width = 0;
    if (elmnt !== null) {
      width = elmnt.clientWidth;
      this.windowSize = width;
    }
  }

  // State Management

  updateState(type, state) {
    switch (type) {
      case "component":
        this.componentState = state;
        break;
      case "tab":
        this.tabState = state;
        break;
      default:
      //ignore
    }
  }

  stopLoading(timeoutValue) {
    setTimeout(() => {
      this.parentLoading = false;
      this.childLoading = false;
      this.healthCheckDetailsLoading = false;
    }, timeoutValue);
  }

  // Data Utilities

  getTheSummaries() {
    this.hidePopups();
    getSummaries({
      format: this.mode,
      theDate: this.selectedDate,
      orgId: this.selectedOrgId,
      maxRows: this.maxRows
    })
      .then((data) => {
        // need to hide again, as date selector causes issues!
        this.updateModeAndState(
          data.mode,
          data.summaries[0].healthCheck.Security_Health_Check_Org__c
        );
        console.log(JSON.stringify(data));
        // set state
        this.applyFilters(data.summaries);
        this.summaryCategories = data.summaryCategories;
        this.hidePopups();
      })
      .catch((error) => {});
  }

  updateModeAndState(mode, orgId) {
    switch (mode) {
      case "bydate":
        this.updateState("component", "multiOrgSummary");
        this.mode = "bydate";
        break;
      case "byorg":
        this.updateState("component", "singleOrgSummary");
        this.mode = "byorg";
        break;
      case "thisorg":
        this.updateState("component", "childOrgSummary");
        this.selectedOrgId = orgId;
        this.getSelectedOrgDetails();
        this.mode = "thisorg";
        break;
      default:
      //
    }
  }

  /* Filter the data according to the current filters */
  applyFilters(inSummaries) {
    let summaries = JSON.parse(JSON.stringify(inSummaries));

    let filters = this.filterValue.join(",");

    let orgFilters = this.filterOrgValue.join(",");

    for (let isummary in summaries) {
      let summary = summaries[isummary];
      summaries[isummary].key = isummary;

      // Check whether this row (i.e. healthCheck) should be shown
      let showSummary = false;

      // check if the summary score is inside values
      let summaryScore = summary.healthCheck.Score__c;

      if (summaryScore >= 69) {
        showSummary = orgFilters.indexOf("Excellent") != -1;
      } else if (summaryScore >= 54) {
        showSummary = orgFilters.indexOf("Good") != -1;
      } else if (orgFilters.indexOf("Poor") != -1) {
        showSummary = true;
      }

      summary.showHealthCheck = showSummary;

      if (summary.healthCheck != undefined && summary.healthCheck.Security_Health_Check_Risks__r) {
        for (let irisk in summary.healthCheck.Security_Health_Check_Risks__r) {
          let risk = summary.healthCheck.Security_Health_Check_Risks__r[irisk];

          risk.showrisk = filters.indexOf(risk.RiskType__c) != -1;
          summary.healthCheck.Security_Health_Check_Risks__r[risk] = risk;
        }
        if (summary.healthCheck.Security_Health_Check_Risks__r) {
          this.numberOfRows = summary.healthCheck.Security_Health_Check_Risks__r.length;
        }
      }
      summaries[isummary] = summary;
    }

    this.summaries = summaries;
    this.stopLoading(500);
  }

  reorderSummaries() {
    if (this.orgSortOrder == "score") {
      this.summaries.sort(this.compareValues("score", "desc"));
    } else {
      this.summaries.sort(this.compareValues("alpha"));
    }
  }
  compareValues(key, order = "asc") {
    return function innerSort(a, b) {
      let myvarA = a.org.Name;
      let myvarB = b.org.Name;
      if (key == "score") {
        myvarA = a.healthCheck.Score__c;
        myvarB = b.healthCheck.Score__c;
      }

      const varA = typeof myvarA === "string" ? myvarA.toUpperCase() : myvarA;
      const varB = typeof myvarB === "string" ? myvarB.toUpperCase() : myvarB;

      let comparison = 0;
      if (varA > varB) {
        comparison = 1;
      } else if (varA < varB) {
        comparison = -1;
      }
      return order === "desc" ? comparison * -1 : comparison;
    };
  }

  showHealthCheckDetail(event) {
    switch (this.componentState) {
      case "multiOrgSummary":
        this.childLoading = true;
        break;
      case "singleOrgSummary":
        this.healthCheckDetailsLoading = true;
        break;
      case "childOrgSummary":
        this.healthCheckDetailsLoading = true;
        break;
      default:
      //
    }
    let selectedHealthCheckId = event.detail;

    for (let key in this.summaries) {
      if (this.summaries[key].healthCheck.Id === selectedHealthCheckId) {
        this.singleHealthCheck = this.processRisks(JSON.parse(JSON.stringify(this.summaries[key])));
        this.singleHealthCheckDate = this.summaries[key].healthCheck.Check_Date__c;
        this.singleHealthCheckSelected = true;
        if (this.componentState === "multiOrgSummary") {
          let tempEvent = { detail: this.summaries[key].org.Id };
          this.showSingleOrg(tempEvent);
        }
      }
    }

    if (this.singleHealthCheckSelected === true) {
      this.stopLoading(100);
      if (this.componentState !== "childOrgSummary") {
        this.updateState("component", "singleOrgSummary");
      }
      this.updateState("tab", "details");
    }
  }

  processRisks(tempHealthCheck) {
    if (tempHealthCheck) {
      let risks = tempHealthCheck.healthCheck.Security_Health_Check_Risks__r;
      let rating = [
        { rating: "HIGH_RISK", label: "Critical", indx: "rating0", risks: [] },
        { rating: "MEDIUM_RISK", label: "Warning", indx: "rating1", risks: [] },
        { rating: "MEETS_STANDARD", label: "Compliant", indx: "rating2", risks: [] }
      ];
      let categoryA = [
        {
          category: "INFORMATIONAL",
          description: "These are minor risks that can be updated to improve security.",
          first: true,
          indx: "cat0",
          label: "Informational",
          allRisks: [],
          ratings: JSON.parse(JSON.stringify(rating))
        },
        {
          category: "LOW_RISK",
          description: "Risks in this category are areas to consider for improvement.",
          first: false,
          indx: "cat1",
          label: "Low Risk",
          allRisks: [],
          ratings: JSON.parse(JSON.stringify(rating))
        },
        {
          category: "MEDIUM_RISK",
          description: "Critical Risks in this category should be addressed as soon as possible.",
          first: false,
          indx: "cat2",
          label: "Medium Risk",
          allRisks: [],
          ratings: JSON.parse(JSON.stringify(rating))
        },
        {
          category: "HIGH_RISK",
          description:
            "Critical and Warning Risks in this category are potentially dangerous and should be addressed as soon as possible.",
          first: false,
          indx: "cat3",
          label: "High Risk",
          allRisks: [],
          ratings: JSON.parse(JSON.stringify(rating))
        }
      ];

      for (let riskindex in risks) {
        let risk = risks[riskindex];
        let riskType = risk.RiskType__c;
        let riskCategory = risk.SettingRiskCategory__c;
        let riskColor = "multioss-cell-text-green";
        let riskLabel = " Compliant";
        if (riskType == "HIGH_RISK") {
          riskColor = "multioss-cell-text-red";
          riskLabel = "Critical";
        } else if (riskType == "MEDIUM_RISK") {
          riskColor = "multioss-cell-text-orange";
          riskLabel = "Warning";
        }
        risk.riskColor = riskColor;
        risk.riskLabel = riskLabel;

        for (let categoryIndex in categoryA) {
          let ratingA = categoryA[categoryIndex].ratings;
          for (let ratingIndex in ratingA) {
            if (
              categoryA[categoryIndex].category == riskCategory &&
              ratingA[ratingIndex].rating == riskType
            ) {
              let currentRisksA = categoryA[categoryIndex].ratings[ratingIndex].risks;
              if (currentRisksA == null) {
                currentRisksA = [];
              }

              currentRisksA.push(risk);
              categoryA[categoryIndex].ratings[ratingIndex].risks = currentRisksA;

              let allRisks = categoryA[categoryIndex].allRisks;
              allRisks.push(risk);
            }
          }
        }
      }
      return categoryA;
    }
  }

  handleOrgSortOrderChange(event) {
    this.orgSortOrder = event.detail.value;
    this.reorderSummaries();
  }

  getSelectedOrgDetails() {
    getCurrentOrgDetails({ selectedOrgId: this.selectedOrgId })
      .then((data) => {
        this.selectedOrgData = data;
        this.daysSinceFirstHealthCheck = data.DaysSinceFirstHealthCheck;
      })
      .catch((error) => {
        this.error = error.message;
      });
  }

  getAdminDetails() {
    getSecurityAdminDetails({ userId: this.selectedOrgData.SecurityAdminId })
      .then((data) => {
        this.updateImageURLs(data);
        this.stopLoading(500);
      })
      .catch((error) => {
        console.log(error.message);
      });
  }

  updateImageURLs(data) {
    let adminData = JSON.parse(JSON.stringify(data));
    for (let key in adminData.SecuritySkills) {
      for (let i in adminData.SecuritySkills[key].Values) {
        let resourceURL =
          this.baseStaticResourceURL +
          adminData.SecuritySkills[key].Values[i].Image_Path__c.substring(23);

        adminData.SecuritySkills[key].Values[i].resourceURL = resourceURL;
      }
    }
    this.securityAdmin = adminData;
  }

  // Actions
  getOrgsByDailySummary() {
    this.mode = "bydate";
    this.updateState("component", "multiOrgSummary");
    this.getTheSummaries();
  }

  maxRowsChanged(event) {
    window.clearTimeout(this.delayTimeout);
    this.maxRows = event.target.value;
    this.delayTimeout = setTimeout(() => {
      this.parentLoading = true;
      this.getTheSummaries();
    }, DELAY);
  }

  getOrgSummary() {
    if (isNaN(this.maxRows)) {
      this.maxRows = 30;
    }
    this.mode = "byorg";
    if (this.componentState !== "childOrgSummary") {
      this.updateState("component", "singleOrgSummary");
    }
    this.getTheSummaries();
  }

  inputChange(event) {
    this[event.target.name] = event.target.value;
    this.getTheSummaries();
    this.childLoading = true;
  }

  handleNavigateToSummary(event) {
    this.childLoading = true;
    this.getOrgsByDailySummary();
  }

  riskSelected(event) {
    let detail = event.detail;
    let selectedRowId = detail.selectedRowId;

    this.selectedRisk = this.findRisk(selectedRowId);
    this.selectedRowId = selectedRowId;
    this.popupLeft = detail.popupLeft;
    this.popupTop = detail.popupTop;
    this.itemWidth = detail.itemWidth;
    this.showPopup = true;
    this.hidePopup = false;
    if (this.componentState === "multiOrgSummary") {
      this.selectedOrgId = detail.orgId;
    }
  }

  getRelatedTasks() {
    getSecurityHealthCheckTasks({ selectedOrgId: this.selectedOrgId })
      .then((data) => {
        this.currentTasks = data;
        this.stopLoading(100);
      })
      .catch((error) => {
        console.log(error.message);
      });
  }

  showRiskModal(event) {
    let riskId = event.detail;
    this.selectedRisk = this.findRisk(riskId);
    this.showRiskDetailModal = true;
  }

  closeRiskDetailModal() {
    this.showRiskDetailModal = false;
  }

  closeGuideModal() {
    this.showGuideModal = false;
  }

  showTaskDetails(event) {
    let taskId = event.currentTarget.dataset.id;
    this.selectedTaskId = taskId;
    this.showTaskDetailModal = true;
  }

  handleFilterChange(event) {
    this.filterValue = event.detail.value;

    this.applyFilters(this.summaries);
  }

  handleFilterOrgChange(event) {
    this.filterOrgValue = event.detail.value;
    // note that we only have the one filter function
    this.applyFilters(this.summaries);
  }

  showCreateTask(event) {
    let details = event.detail;
    this.taskRiskId = details.riskId;
    this.taskOrgId = details.orgId;
    this.showCreateTaskModal = true;
  }

  closeCreateTask() {
    this.taskRiskId = "";
    this.taskOrgId = "";
    this.showCreateTaskModal = false;
    this.getRelatedTasks();
    if (this.tabState === "tasks") {
      this.childLoading = true;
    }
  }

  closeTaskDetail() {
    this.showTaskDetailModal = false;
    this.getRelatedTasks();
    if (this.tabState === "tasks") {
      this.childLoading = true;
    }
  }

  showSecuritySyncModal() {
    this.template.querySelector("c-multi-org-summary-scheduler").openSyncSchedule();
  }

  riskDeselected(event) {
    this.hidePopup = true;
    setTimeout(() => {
      this.hideData(event);
    }, 1000);
  }

  showData() {
    this.hidePopup = false;
  }

  hideData() {
    if (this.hidePopup === true) {
      this.showPopup = false;
    }
  }

  // force the hide of popups
  hidePopups() {
    this.hidePopup = true;
    this.hideData();
  }

  dateSelected(event) {
    this.childLoading = true;
    let selectedDate = event.detail;
    this.selectedDate = selectedDate;
    this.getOrgsByDailySummary();
  }

  showSingleOrg(event) {
    let orgId = event.detail;
    this.selectedOrgId = orgId;
    this.navigateToTopOfPage();
    this.parentLoading = true;
    this.childLoading = true;
    this.getOrgSummary();
    this.getSelectedOrgDetails();
    this.getRelatedTasks();
  }

  findRisk(selectedRowId) {
    for (let isummary in this.summaries) {
      let summary = this.summaries[isummary];
      for (let irisk in summary.healthCheck.Security_Health_Check_Risks__r) {
        let risk = summary.healthCheck.Security_Health_Check_Risks__r[irisk];

        if (risk.Id == selectedRowId) {
          return risk;
        }
      }
    }
    return null;
  }

  closeConfigurationModal() {
    this.showOrgConfigurationModal = false;
  }

  navigateToOrgDetails(event) {
    let recordId = event.detail;

    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: recordId,
        objectApiName: "Security_Health_Check_Org__c",
        actionName: "view"
      }
    });
  }

  showOrgConfiguration() {
    this.showOrgConfigurationModal = true;
  }

  navigateToTopOfPage() {
    this.template.querySelector(".multioss-component-container").scrollTop = 0;
  }

  markTaskCompleted(event) {
    let taskId = event.currentTarget.dataset.id;

    const fields = {};
    fields[ID_FIELD.fieldApiName] = taskId;
    fields[STATUS_FIELD.fieldApiName] = "Completed";
    const recordInput = { fields };
    updateRecord(recordInput)
      .then((data) => {
        this.childLoading = true;
        this.getRelatedTasks();
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Success",
            message: "Security Task Completed",
            variant: "success"
          })
        );
      })
      .catch((error) => {
        console.log(error.message);
      });
  }

  viewGuide() {
    this.showGuideModal = true;
  }

  setActiveTab(event) {
    let selectedTab = event.target.value;
    if (this.tabState !== selectedTab) {
      this.updateState("tab", selectedTab);

      if (selectedTab === "details") {
        let selectedRecord = { detail: this.selectedOrgData.LatestHealthCheckId };
        this.showHealthCheckDetail(selectedRecord);
      }

      if (selectedTab === "tasks") {
        this.getRelatedTasks();
        this.childLoading = true;
      }
      if (selectedTab === "admin") {
        this.getAdminDetails();
        this.childLoading = true;
      }
    }
  }

  // Dynamic Rendering
  get orgSortOrderOptions() {
    return [
      { label: "By Name", value: "alpha" },
      { label: "By Score", value: "score" }
    ];
  }

  get shouldIShowNoDataBanner() {
    if (this.summaries === null || this.summaries.length === 0) {
      return true;
    }
    return false;
  }

  get shouldIShowOrgSummary() {
    if (this.mode === "bydate") {
      return true;
    }
    return false;
  }

  get shouldIShowDateSummary() {
    if (this.mode === "byorg") {
      return true;
    }
    return false;
  }

  get shouldIShowThisOrgSummary() {
    if (this.mode === "thisorg") {
      return true;
    }
    return false;
  }

  get orgLabel() {
    return this.selectedOrgData.Name;
  }

  get orgRecordId() {
    try {
      let firstEntry = this.summaries[0];
      let orgId = firstEntry.org.Id;

      return orgId;
    } catch (e) {
      return "";
    }
  }

  get filterOptions() {
    return [
      { label: "Critical", value: "HIGH_RISK" },
      { label: "Warning", value: "MEDIUM_RISK" },
      { label: "Compliant", value: "MEETS_STANDARD" }
    ];
  }

  get filterOrgOptions() {
    return [
      { label: "Excellent", value: "Excellent" },
      { label: "Good", value: "Good" },
      { label: "Poor", value: "Poor" }
    ];
  }

  get selectedFilterOrgValues() {
    return this.filterOrgValue.join(",");
  }

  get selectedFilterValues() {
    return this.filterValue.join(",");
  }

  get showSingleHealthCheckDetails() {
    return this.selectedOrgData.LatestHealthCheckId !== null;
  }

  get showSecurityHealthCheckTasks() {
    if (this.currentTasks !== null) {
      return this.currentTasks.length > 0;
    }
  }

  get emptyOrgOverviewState() {
    if (this.componentState === "singleOrg" && this.summaries.length === 0) {
      return true;
    }
  }

  get totalOpenTasks() {
    let i = 0;

    if (this.currentTasks != null) {
      for (let key in this.currentTasks) {
        let status = this.currentTasks[key].Status__c;

        if (status === "Created" || status === "In Progress") {
          i++;
        }
      }
    }

    return i;
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

  get setupState() {
    return this.componentState === "notSetup";
  }
}
