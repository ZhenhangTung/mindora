import { Controller } from "@hotwired/stimulus"

// FIXME: auto scrolling doesn't work
export default class extends Controller {
  static targets = ["messagesContainer", "messageTextArea", "messages", "form"]

  connect() {
    this.element.addEventListener('turbo:submit-end', () => this.clearMessage()) // clear message after submit

    this.scrollToBottom()
  }

  scrollToBottom() {
    this.messagesContainerTarget.scrollTop = this.messagesContainerTarget.scrollHeight
  }

  clearMessage() {
    this.messageTextAreaTarget.value = ''
  }

  submit(event) {
    const messageText = this.messageTextAreaTarget.value;
    if (messageText.trim() === "") {
      return; // Prevent empty messages
    }
    
    // optimistic UI update
    this.addMessage(messageText)
    this.scrollToBottom()
  }

  addMessage(text) {
    const messageHTML = `
      <div class="chat chat-end">
        <div class="chat-image avatar">
          <div class="w-10 rounded-full">
            <img alt="Chat Avatar" src="https://daisyui.com/images/stock/photo-1534528741775-53994a69daeb.jpg" />
          </div>
        </div>
        <div class="chat-bubble">
          ${text}
        </div>
      </div>
    `;

    this.messagesTarget.insertAdjacentHTML("beforeend", messageHTML);
  }
}

