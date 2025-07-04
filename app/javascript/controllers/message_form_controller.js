import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  submitOnEnter(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      const form = this.element.closest('form')
      if (form) {
        form.requestSubmit()
        this.scrollMessagesToBottom()
      }
    }
  }

  scrollMessagesToBottom() {
    const messagesContainer = document.querySelector('[data-controller="auto-scroll"]')
    if (messagesContainer) {
      messagesContainer.scrollTop = messagesContainer.scrollHeight
    }
  }
}