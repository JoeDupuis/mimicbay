import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["targetSelect", "areaSelect", "characterSelect", "form", "impersonationSection", "toggleText"]

  connect() {
    this.toggleTargetSelect()
    this.setupFormInterception()
  }

  toggleTargetSelect() {
    const targetType = this.targetSelectTarget.value

    // Hide all select fields first and clear their values
    this.hideAndClearSelect(this.areaSelectTarget)
    this.hideAndClearSelect(this.characterSelectTarget)

    // Show the appropriate select field
    if (targetType === 'area') {
      this.areaSelectTarget.classList.remove('hidden')
    } else if (targetType === 'character') {
      this.characterSelectTarget.classList.remove('hidden')
    }
    // If 'all', both remain hidden
  }

  hideAndClearSelect(selectElement) {
    selectElement.classList.add('hidden')
    // Find the select input within the container and clear its value
    const select = selectElement.querySelector('select')
    if (select) {
      select.value = ''
    }
  }

  setupFormInterception() {
    if (this.hasFormTarget) {
      const form = this.formTarget
      form.addEventListener('submit', (e) => {
        // Add the target selection values to the form
        const targetType = this.targetSelectTarget.value
        const formData = new FormData(form)
        
        formData.append('message[target_type]', targetType)
        
        if (targetType === 'area') {
          const areaId = this.areaSelectTarget.querySelector('select').value
          if (areaId) formData.append('message[area_id]', areaId)
        } else if (targetType === 'character') {
          const characterId = this.characterSelectTarget.querySelector('select').value
          if (characterId) formData.append('message[target_character_id]', characterId)
        }
      })
    }
  }

  toggleImpersonation() {
    if (this.hasImpersonationSectionTarget) {
      this.impersonationSectionTarget.classList.toggle('hidden')
      
      if (this.hasToggleTextTarget) {
        const isHidden = this.impersonationSectionTarget.classList.contains('hidden')
        this.toggleTextTarget.textContent = isHidden ? 'Show Character Views' : 'Hide Character Views'
      }
    }
  }
}