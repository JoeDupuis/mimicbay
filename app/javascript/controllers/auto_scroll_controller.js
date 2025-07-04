import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.scrollToBottom()
    this.setupScrollTracking()
    this.setupMutationObserver()
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
    if (this.scrollHandler) {
      this.element.removeEventListener('scroll', this.scrollHandler)
    }
  }

  setupScrollTracking() {
    this.wasAtBottom = true
    
    this.scrollHandler = () => {
      this.wasAtBottom = this.isAtBottom()
    }
    
    this.element.addEventListener('scroll', this.scrollHandler)
  }

  setupMutationObserver() {
    this.observer = new MutationObserver((mutations) => {
      if (this.wasAtBottom) {
        requestAnimationFrame(() => {
          this.scrollToBottom()
          this.wasAtBottom = true
        })
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
    if (this.wasAtBottom) {
      this.scrollToBottom()
    }
  }
}