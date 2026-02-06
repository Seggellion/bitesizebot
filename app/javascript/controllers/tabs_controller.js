import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]
  static classes = ["active", "inactive"]

  switch(event) {
    const selectedId = event.currentTarget.dataset.tabId

    // 1. Toggle Panels
    this.panelTargets.forEach(panel => {
      panel.classList.toggle("hidden", panel.id !== selectedId)
    })

    // 2. Toggle Button Styling
    this.tabTargets.forEach(tab => {
      const isActive = tab.dataset.tabId === selectedId
      tab.classList.toggle(...this.activeClasses, isActive)
      tab.classList.toggle(...this.inactiveClasses, !isActive)
    })
  }
}