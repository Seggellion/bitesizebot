import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["scroller"]
  static classes = ["open"]

  connect () {
    window.addEventListener("gallery:open-lightbox", ({ detail }) =>
      this.show(detail.index))

        window.addEventListener("keydown", this.handleKeydown)

  }

  disconnect() {
    window.removeEventListener("gallery:open-lightbox", this.handleOpen)
    window.removeEventListener("keydown", this.handleKeydown)
  }

  handleOpen = ({ detail }) => this.show(detail.index)
  handleKeydown = (event) => {
    if (event.key === "Escape" || event.key === "Esc") {
      this.close()
    }
  }

  show (index = 0) {
    this.element.classList.add(this.openClass)
    document.body.style.overflow = "hidden"
    // snap to the requested slide
    const fig = this.scrollerTarget.children[index]
    fig && fig.scrollIntoView({ block: "start", behavior: "instant" })
  }

  close () {
    this.element.classList.remove(this.openClass)
    document.body.style.overflow = ""
  }

  scrollTo (e) {
    const index = parseInt(e.params.index, 10)
    const fig = this.scrollerTarget.children[index]
    fig && fig.scrollIntoView({ block: "start", behavior: "smooth" })
  }
  
}
