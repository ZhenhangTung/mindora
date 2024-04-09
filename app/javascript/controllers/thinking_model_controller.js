import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["input", "messages"]

    connect() {
        this.loadMessages()
    }

    loadMessages() {

    }

    submit(event) {
        alert('ok')
    }

    sendMessage(message) {

    }

    addMessage(content) {

    }
}