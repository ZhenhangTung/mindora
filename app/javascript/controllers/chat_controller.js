import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static targets = ["messagesContainer", "messageTextArea", "messages"]

  connect() {
    // this.element.addEventListener('turbo:submit-end', () => this.clearMessage()) // clear message after submit

    this.scrollToBottom()

    // FIXME: auto scrolling doesn't work
    // console.log(this.messagesContainerTarget)
    // this.messagesContainerTarget.addEventListener('turbo:load', () => this.scrollToBottom()) // scroll to bottom after render
    // this.observer = new MutationObserver(() => this.scrollToBottom());
    // this.observer.observe(this.element, { childList: true });
    // document.addEventListener('turbo:frame-load', () => this.scrollToBottom())
  }

  scrollToBottom() {
    this.messagesContainerTarget.scrollTop = this.messagesContainerTarget.scrollHeight
  }

  clearMessage() {
    this.messageTextAreaTarget.value = ''
  }

  submit(event) {
    event.preventDefault();

    const messageText = this.messageTextAreaTarget.value;
    if (messageText.trim() === "") {
      return; // Prevent empty messages
    }
    console.log(messageText)
    //
    this.addMessage(messageText)
    this.clearMessage()
    this.scrollToBottom()

    // TODO: Submit the form data to the server
    Turbo.visit(this.element.getAttribute('action'), {
      method: this.element.getAttribute('method'),
      body: new FormData(this.element)
    });
  }

  addMessage(text) {
    const messageHTML = `
      <div class="chat chat-end">
        <div class="chat-image avatar">
          <div class="w-10 rounded-full">
            <img alt="Chat Avatar" src="https://files.olavibe.com/image/DALL%C2%B7E%202023-12-20%2007.31.52%20-%20A%20digital%20portrait%20of%20a%20person%20with%20a%20neutral%20expression%2C%20illuminated%20by%20soft%20blue%20lighting%20on%20one%20side%20of%20the%20face%20and%20warm%20pink%20lighting%20on%20the%20othe.png" />
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

