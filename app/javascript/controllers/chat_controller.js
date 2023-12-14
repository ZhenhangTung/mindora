import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.scrollToBottom()
  }

  scrollToBottom() {
    const element = this.element
    element.scrollTop = element.scrollHeight
  }
}

