import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="trix"
export default class extends Controller {
  static targets = ["content"];

  connect() {
    this.updateLinks();
    this.applyAlternatingAlignment();
    this.element.addEventListener("trix-attachment-add", this.sanitizeAttachment);

      // 👇 new: detect image clicks
   // 👇 Corrected: detect clicks on images inside the content
    this.contentTarget.addEventListener("click", event => {
      const img = event.target.closest(".attachment--preview img");
      if (!img) return;

      // Gather all images inside the Trix content
      const images = Array.from(
        this.contentTarget.querySelectorAll(".attachment--preview img")
      );

      // Determine the index of the clicked image
      const index = images.indexOf(img);

      // ✅ Dispatch event to the lightbox controller
      window.dispatchEvent(
        new CustomEvent("gallery:open-lightbox", { detail: { index } })
      );
    });
  }

  disconnect() {
    this.element.removeEventListener("trix-attachment-add", this.sanitizeAttachment);
  }

  sanitizeAttachment(event) {
    const attachment = event.attachment;
    if (!attachment.file) {
      delete attachment.attributes.url;
      delete attachment.attributes.href;
      delete attachment.attributes.filename;
      delete attachment.attributes.filesize;
      delete attachment.attributes.width;
      delete attachment.attributes.height;
      delete attachment.attributes.previewable;
      delete attachment.attributes.presentation;
    }
  }

  updateLinks() {
    this.contentTarget.querySelectorAll("a").forEach(link => {
      link.setAttribute("target", "_blank");
    });
  }


  
  // 👇 New method: alternate image alignment
  applyAlternatingAlignment() {
    const attachments = this.contentTarget.querySelectorAll("action-text-attachment");
    attachments.forEach((attachment, index) => {
      const figure = attachment.querySelector(".attachment--preview");
      if (!figure) return;

      // Reset any existing alignment classes
      figure.classList.remove("float-left", "float-right");

      // Alternate alignment based on index
      if (index % 2 === 0) {
        figure.classList.add("float-right");
      } else {
        figure.classList.add("float-left");
      }
    });
  }
}
