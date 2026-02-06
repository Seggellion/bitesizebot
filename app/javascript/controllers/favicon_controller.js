import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    originalSrc: String,
    alertSrc: String,
    pending: Boolean 
  }

  connect() {
    this.favicon = document.getElementById("favicon-link")
    if (!this.favicon) return

    // Capture the original href exactly as it is
    this.originalSrcValue = this.favicon.getAttribute("href")
    this.isAlerting = false
    
    if (this.pendingValue) {
      this.alert()
    }
  }

  // Logic to start the alert
  alert(event) {
    if (this.isAlerting) return
    this.isAlerting = true

    let showingAlert = false
    this.flickerTimer = setInterval(() => {
      showingAlert = !showingAlert
      const nextHref = showingAlert ? this.alertSrcValue : this.originalSrcValue
      this.favicon.setAttribute("href", nextHref)
    }, 500)
  }

  // Logic to stop the alert
  clear(event) {
    this.isAlerting = false
    if (this.flickerTimer) {
      clearInterval(this.flickerTimer)
      this.flickerTimer = null
    }
    if (this.favicon) {
      this.favicon.setAttribute("href", this.originalSrcValue)
    }
  }

  disconnect() {
    this.clear()
  }
}