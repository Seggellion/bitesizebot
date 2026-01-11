import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
static values = { images: Array, mobileBreakpoint: Number }
  static targets = ["mobileTrack", "dot"]

  connect () {
    console.log('gallery loaded');
    this.observeResize()
  }

  /* ---- desktop ---- */
  open (e) {
    console.log('opened');
    if (window.innerWidth < this.mobileBreakpointValue) return
    const index = parseInt(e.params.index, 10)
    this.dispatch("open-lightbox", { detail: { index, images: this.imagesValue } })
  }

  /* ---- mobile carousel ---- */
  observeResize () {
    if (!this.hasMobileTrackTarget) return
    const track = this.mobileTrackTarget
    track.addEventListener("scroll", () => {
      const i = Math.round(track.scrollLeft / track.clientWidth)
      this.dotTargets.forEach((d, idx) =>
        d.classList.toggle("bg-white", idx === i))
    })
  }
}
