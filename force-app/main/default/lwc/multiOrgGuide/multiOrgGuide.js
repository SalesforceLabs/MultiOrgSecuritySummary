import { LightningElement, track } from "lwc";
import guideImages from "@salesforce/resourceUrl/guideImages";

export default class MultiOrgGuide extends LightningElement {
  // Expose URL of assets included inside an archive file
  startImage = guideImages + "/OverviewGuide.png";
  analyseImage = guideImages + "/Analyse.png";
  improveImage = guideImages + "/Improve.png";
  stage = "0";

  connectedCallback() {
    this.stage = "1";
  }

  get shouldIShowStage1() {
    return this.stage == "1";
  }

  get shouldIShowStage2() {
    return this.stage == "2";
  }

  get shouldIShowStage3() {
    return this.stage == "3";
  }

  get shouldIShowStage4() {
    return this.stage == "4";
  }

  get atTheEnd() {
    let stageI = parseInt(this.stage);
    console.log("Inside atThEnd stageI is " + stageI);
    return stageI >= 4;
  }

  get atTheStart() {
    let stageI = parseInt(this.stage);
    return stageI <= 1;
  }

  cancelGuideSelected() {
    const myEvent = new CustomEvent("closeguide");
    this.dispatchEvent(myEvent);
  }

  nextGuideSelected() {
    console.log("Inside nextGuideSelected");
    let stageI = parseInt(this.stage) + 1;
    this.stage = "" + stageI;
  }

  prevGuideSelected() {
    console.log("Inside nextGuideSelected");
    let stageI = parseInt(this.stage) - 1;
    this.stage = "" + stageI;
  }
}
