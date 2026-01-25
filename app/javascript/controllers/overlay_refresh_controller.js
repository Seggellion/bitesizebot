import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { ended: Boolean }

  connect() {
    if (this.endedValue) {
      // Small delay so OBS viewers see the win notification
      setTimeout(() => {
        window.location.reload()
      }, 3000)
    }
  }
}
