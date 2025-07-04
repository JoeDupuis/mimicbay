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
      this.dispatch("messageSent")
    }
  }

  clearOnSuccess(event) {
    if (event.detail.success && this.hasInputTarget) {
      this.inputTarget.value = ""
      this.inputTarget.focus()
    }
  }

  dispatch(eventName, detail = {}) {
    this.element.dispatchEvent(new CustomEvent(eventName, { 
      detail, 
      bubbles: true 
    }))
  }
}