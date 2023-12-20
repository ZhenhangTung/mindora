import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messagesContainer"]

  connect() {
    this.element.addEventListener('turbo:submit-end', () => this.clearMessage()) // clear message after submit
    // FIXME: this doesn't work
    this.element.addEventListener('turbo:after-stream-render', () => this.scrollToBottom()) // scroll to bottom after render
    this.scrollToBottom()
  }

  scrollToBottom() {
    const element = this.messagesContainerTarget
    element.scrollTop = element.scrollHeight
  }

  clearMessage() {
    this.messageTarget.value = ''
  }
}

