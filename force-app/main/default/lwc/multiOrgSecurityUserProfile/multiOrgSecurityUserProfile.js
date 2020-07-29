import { LightningElement, api, track } from "lwc";
import getAdminSkillsToManage from "@salesforce/apex/MultiOrgSecuritySummaryService.getAdminSkillsToManage";
import getSecurityAdminDetails from "@salesforce/apex/MultiOrgSecuritySummaryService.getSecurityAdminDetails";
import courseImages from "@salesforce/resourceUrl/courseImages";

export default class MultiOrgSecurityUserProfile extends LightningElement {
  @api recordId;
  @api securityAdmin;
  @api availableSkills;
  showUserSkillsModal;
  @track baseStaticResourceURL = courseImages + "/";
  state;
  loading;

  connectedCallback() {
    if (this.recordId) {
      this.state = "record";
      this.loading = true;
      this.getAdminDetails();
      console.log("record: " + this.recordId);
    } else {
      this.state = "app";
      console.log("app");
    }
  }

  getAdminDetails() {
    getSecurityAdminDetails({ userId: this.recordId })
      .then((data) => {
        this.updateImageURLs(data);
      })
      .catch((error) => {
        //todo: handle error
      });
  }

  updateImageURLs(data) {
    let adminData = JSON.parse(JSON.stringify(data));

    for (let key in adminData.SecuritySkills) {
      for (let i in adminData.SecuritySkills[key].Values) {
        let resourceURL = this.baseStaticResourceURL + adminData.SecuritySkills[key].Values[i].multioss__Image_Path__c.substring(23);

        adminData.SecuritySkills[key].Values[i].resourceURL = resourceURL;
      }
    }
    this.securityAdmin = adminData;
    this.stopLoading(500);
  }

  getAdminSkillsToManage() {
    getAdminSkillsToManage({ userId: this.securityAdmin.UserInfo.Id, staticResourceUrlString: this.baseStaticResourceURL })
      .then((data) => {
        console.log(JSON.stringify(data));
        this.availableSkills = data;
      })
      .catch((error) => {
        console.log(error.message);
      });
  }

  viewLink(event) {
    let url = event.currentTarget.dataset.id;

    window.open(url, "_blank");
  }

  showSkills() {
    this.getAdminSkillsToManage();
    this.showUserSkillsModal = true;
  }

  closeModal() {
    this.showUserSkillsModal = false;
    if (this.recordId) {
      this.state = "record";
      this.loading = true;
      this.getAdminDetails();
      console.log("record: " + this.recordId);
    } else {
      this.state = "app";
      console.log("app");
    }
  }

  get securitySuperstar() {
    return this.securityAdmin.Points > this.securityAdmin.SecuritySuperstarThreshold;
  }

  stopLoading(timeoutValue) {
    setTimeout(() => {
      this.loading = false;
    }, timeoutValue);
  }

  get appState() {
    return this.state === "app";
  }

  get showAdminSkills() {
    if (this.securityAdmin.SecuritySkills) {
      if (this.securityAdmin.SecuritySkills.length >= 1) {
        return true;
      }
    }

    return false;
  }
}
