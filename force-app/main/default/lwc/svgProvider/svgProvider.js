import { LightningElement, api } from "lwc";
import svgShowDesert from "./svgDesert.html";
import svgShowEmpty from "./svgShowEmpty.html";
import svgGoneFishing from "./svgGoneFishing.html";

export default class SvgProvider extends LightningElement {
  @api message;
  @api svgname;

  renderHtml = {
    showdesert: svgShowDesert,
    showempty: svgShowEmpty,
    gonefishing: svgGoneFishing
  };

  render() {
    if (this.renderHtml[this.svgname]) {
      return this.renderHtml[this.svgname];
    } else {
      return svgShowEmpty;
    }
  }
}
