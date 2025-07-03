import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["targetSelect", "areaSelect", "characterSelect"]

  connect() {
    this.toggleTargetSelect()
  }

  toggleTargetSelect() {
    const targetType = this.targetSelectTarget.value

    // Hide all select fields first
    this.areaSelectTarget.classList.add('hidden')
    this.characterSelectTarget.classList.add('hidden')

    // Show the appropriate select field
    if (targetType === 'area') {
      this.areaSelectTarget.classList.remove('hidden')
    } else if (targetType === 'character') {
      this.characterSelectTarget.classList.remove('hidden')
    }
    // If 'all', both remain hidden
  }
}