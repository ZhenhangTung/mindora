import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["message"]

  connect() {
    this.scrollToBottom()
    this.element.addEventListener('turbo:submit-end', () => this.clearMessage()) // clear message after submit

    // FIXME: this doesn't work
    // this.element.addEventListener('turbo:after-stream-render', () => this.scrollToBottom()) // scroll to bottom after render
  }

  scrollToBottom() {
    const element = this.element
    element.scrollTop = element.scrollHeight
  }

  clearMessage() {
    this.messageTarget.value = ''
  }
}

