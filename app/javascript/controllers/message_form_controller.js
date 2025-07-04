import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  connect() {
    this.element.addEventListener("turbo:submit-end", this.clearOnSuccess.bind(this))
  }

  disconnect() {
    this.element.removeEventListener("turbo:submit-end", this.clearOnSuccess.bind(this))
  }

  submitOnEnter(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      this.element.requestSubmit()
      this.scrollMessagesToBottom()
    }
  }

  clearOnSuccess(event) {
    if (event.detail.success && this.hasInputTarget) {
      this.inputTarget.value = ""
      this.inputTarget.focus()
    }
  }

  scrollMessagesToBottom() {
    const messagesContainer = document.querySelector('[data-controller="auto-scroll"]')
    if (messagesContainer) {
      messagesContainer.scrollTop = messagesContainer.scrollHeight
    }
  }
}