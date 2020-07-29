import { api, LightningElement } from "lwc";
import { createRecord } from "lightning/uiRecordApi";
import { deleteRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import SKILLS_OBJECT from "@salesforce/schema/Admin_Security_Skill__c";
import SKILLID_FIELD from "@salesforce/schema/Admin_Security_Skill__c.Security_Skill__c";
import USERID_FIELD from "@salesforce/schema/Admin_Security_Skill__c.User__c";

export default class MultiOrgSecurityUserSkills extends LightningElement {
  @api securityAdmin;
  @api availableSkills;
  @api recordId;

  handleSkillChange(event) {
    let value = event.target.checked;
    let skillId = event.currentTarget.dataset.id;
    let adminSkillId = event.currentTarget.dataset.adminid;
    console.log(skillId);
    console.log(adminSkillId);
    if (value) {
      this.createAdminSkill(skillId);
    } else {
      this.deleteAdminSkill(adminSkillId);
    }
  }

  closeModal() {
    const myEvent = new CustomEvent("closeskillmodal");
    this.dispatchEvent(myEvent);
  }

  createAdminSkill(skillId) {
    const fields = {};
    fields[SKILLID_FIELD.fieldApiName] = skillId;
    fields[USERID_FIELD.fieldApiName] = this.recordId;
    const recordInput = { apiName: SKILLS_OBJECT.objectApiName, fields };
    createRecord(recordInput)
      .then((data) => {
        console.log("success");
      })
      .catch((error) => {
        console.log(JSON.stringify(error));
      });

    console.log(skillId);
  }

  deleteAdminSkill(skillId) {
    deleteRecord(skillId)
      .then((data) => {})
      .catch((error) => {
        console.log(JSON.stringify(error));
      });
  }
}
