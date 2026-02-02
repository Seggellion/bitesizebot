import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { ended: Boolean }

  connect() {
    if (this.endedValue) {
      setTimeout(() => {
        // Force a hard refresh with a cache-buster param
        const url = new URL(window.location.href);
        url.searchParams.set('refresh', Date.now());
        window.location.href = url.toString();
      }, 16500)
    }
  }
}