import { Controller } from "@hotwired/stimulus"



export default class extends Controller {
  static targets = ["input", "list"]
  static values  = { productId: Number }

  handleKeydown(event) {
    if (event.key === "Enter") {
      event.preventDefault()
      const name = this.inputTarget.value.trim()
      if (name.length) this.addTag(name)
    }
  }

  addTag(name) {
    fetch(`/admin/products/${this.productIdValue}/add_tag`, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({ name })
    })
      .then(r => r.text())
      .then(html => {
        this.listTarget.insertAdjacentHTML("beforeend", html)
        this.inputTarget.value = ""
      })
  }

remove(event) {
  const button   = event.currentTarget          // keep a reference
  const pill     = button.parentElement         // the <span> “pill”
  const tagId    = button.dataset.tagId

  fetch(`/admin/products/${this.productIdValue}/remove_tag/${tagId}`, {
    method: "DELETE",
    headers: {
      "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
    }
  }).then(() => {
    pill?.remove()                              // delete from the DOM
  }).catch(console.error)                       // optional: log failures
}

}