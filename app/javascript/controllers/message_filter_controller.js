import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["message"]

  filter(event) {
    const filterValue = event.target.value

    this.messageTargets.forEach(message => {
      if (filterValue === 'all') {
        this.showMessage(message)
      } else if (filterValue === 'private') {
        // Show only messages without area
        if (!message.dataset.areaId || message.dataset.areaId === '') {
          this.showMessage(message)
        } else {
          this.hideMessage(message)
        }
      } else if (filterValue.startsWith('area-')) {
        // Show only messages from specific area
        const areaId = filterValue.replace('area-', '')
        if (message.dataset.areaId === areaId) {
          this.showMessage(message)
        } else {
          this.hideMessage(message)
        }
      }
    })
  }

  showMessage(message) {
    message.classList.remove('hidden')
  }

  hideMessage(message) {
    message.classList.add('hidden')
  }
}