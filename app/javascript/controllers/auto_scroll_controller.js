import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.scrollToBottom()
    this.setupMutationObserver()
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  setupMutationObserver() {
    this.observer = new MutationObserver(() => {
      if (this.isAtBottom()) {
        this.scrollToBottom()
      }
    })

    this.observer.observe(this.element, {
      childList: true,
      subtree: true
    })
  }

  isAtBottom() {
    const threshold = 50
    return this.element.scrollHeight - this.element.scrollTop - this.element.clientHeight < threshold
  }

  scrollToBottom() {
    this.element.scrollTop = this.element.scrollHeight
  }

  childrenChanged() {
    if (this.isAtBottom()) {
      this.scrollToBottom()
    }
  }
}