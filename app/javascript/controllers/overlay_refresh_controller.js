import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static values = { ended: Boolean }

  connect() {
    if (this.endedValue) {
      setTimeout(() => {
        // Clear Turbo cache and force a fresh visit
        Turbo.cache.clear()
        Turbo.visit(window.location.pathname, { action: "replace" })
      }, 3000)
    }
  }
}