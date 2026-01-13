// app/javascript/controllers/bingo_item_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["column", "row"]

  connect() {
    this.updateRows()
  }

  updateRows() {
    const ranges = {
      'B': { min: 1, max: 15 },
      'I': { min: 16, max: 30 },
      'N': { min: 31, max: 45 },
      'G': { min: 46, max: 60 },
      'O': { min: 61, max: 75 }
    }

    // Force to string and trim to avoid any Rails-side formatting issues
    const selectedColumn = String(this.columnTarget.value).trim()
    
    console.log("Selected Column:", selectedColumn) // Debugging: check your browser console

    const range = ranges[selectedColumn]

    // Clear the dropdown
    this.rowTarget.innerHTML = ""
    
    if (range) {
      // Add a placeholder
      let placeholder = document.createElement("option")
      placeholder.text = "Select Number"
      placeholder.value = ""
      this.rowTarget.appendChild(placeholder)

        for (let i = range.min; i <= range.max; i++) {
        let option = document.createElement("option")
        option.value = i
        option.text = i
        
        // Convert dataset value to Number for a clean comparison
        if (Number(this.rowTarget.dataset.selectedValue) === i) {
            option.selected = true
        }
        
        this.rowTarget.appendChild(option)
        }
      this.rowTarget.disabled = false
    } else {
      let option = document.createElement("option")
      option.text = "Select Column First"
      this.rowTarget.appendChild(option)
      this.rowTarget.disabled = true
    }
  }
}