import { Controller } from "@hotwired/stimulus"

const localStorageKey = "PMWW_ChatHistory_Challenges"

export default class extends Controller {
  static targets = ["model", "input", "messages", "submitButton"]

  connect() {
    this.restoreChatFromLocalStorage()
    document.addEventListener("chat-data-received", this.handleDataReceived);
  }

  disconnect() {
    document.removeEventListener("chat-data-received", this.handleDataReceived);
  }

  restoreChatFromLocalStorage() {
    let chatHistory = this.getRecentChatHistory(-1);

    chatHistory.forEach(chat => {
      this.appendMessage(chat.role, chat.content);
    });
  }

  getRecentChatHistory(count = 10) {
    let chatHistory = JSON.parse(localStorage.getItem(localStorageKey)) || [];

    return count > 0 ? chatHistory.slice(-count) : chatHistory;
  }

  submit(event) {
    event.preventDefault()
    this.disableButton()

    const userInput = this.inputTarget.value

    const recentMessages = this.getRecentChatHistory(6);

    const data = {
      user_input: userInput,
      chat_history: recentMessages
    }

    this.saveChatToLocalStorage("user", userInput)
    this.appendMessage("user", userInput)
    this.clearInput()

    fetch("/chat", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").getAttribute("content") // 确保在 Rails 中包含 CSRF 令牌
      },
      body: JSON.stringify(data)
    })
        .then(response => response.json())
        .then(data => {
          console.log("Success:", data)
          this.appendMessage("assistant", data.content)
          this.saveChatToLocalStorage("assistant", data.content);
        })
        .catch((error) => {
          console.error("Error:", error)
          alert("发生错误:", error)
        }).finally(() => {
      this.enableButton()
    });
  }

  appendMessage(role, message) {
    const div = document.createElement("div")
    div.classList.add("flex", "items-start")
    if (role === "user") {
      div.classList.add("flex-row-reverse")
      div.innerHTML = `
        <img class="ml-2 h-8 w-8 rounded-full" src="https://dummyimage.com/128x128/354ea1/ffffff&text=我" />
        <div class="min-h-[85px] rounded-b-xl rounded-tl-xl bg-slate-50 p-4 dark:bg-slate-800 sm:min-h-0 sm:max-w-md md:max-w-2xl">
            <p>${message.split("\n\n").join("</p><p>").split("\n").join("<br>")}</p>
        </div>
      `
    } else {  // assistant
      div.innerHTML = `
        <img class="mr-2 h-8 w-8 rounded-full" src="https://dummyimage.com/128x128/363536/ffffff&text=汪" />
        <div class="rounded-b-xl rounded-tr-xl bg-slate-50 p-4 dark:bg-slate-800 sm:max-w-md md:max-w-2xl">
            <p>${message.split("\n\n").join("</p><p>").split("\n").join("<br>")}</p>
        </div>
      `
    }

    this.messagesTarget.appendChild(div)  // 确保你的 HTML 里有 data-thinking-model-target="messages"
    this.scrollToBottom();
  }

  saveChatToLocalStorage(role, content) {
    let chatHistory = JSON.parse(localStorage.getItem(localStorageKey)) || [];

    chatHistory.push({ role, content });

    localStorage.setItem(localStorageKey, JSON.stringify(chatHistory));
  }

  clearInput() {
    this.inputTarget.value = ""
  }

  scrollToBottom() {
    const messagesContainer = this.messagesTarget;
    messagesContainer.scrollTop = messagesContainer.scrollHeight;
  }

  disableButton() {
    const icon = this.submitButtonTarget.querySelector('svg');
    icon.outerHTML = `<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-6">
      <path stroke-linecap="round" stroke-linejoin="round" d="M6.75 12a.75.75 0 1 1-1.5 0 .75.75 0 0 1 1.5 0ZM12.75 12a.75.75 0 1 1-1.5 0 .75.75 0 0 1 1.5 0ZM18.75 12a.75.75 0 1 1-1.5 0 .75.75 0 0 1 1.5 0Z" />
    </svg>`;
    this.submitButtonTarget.disabled = true;
  }

  enableButton() {
    const icon = this.submitButtonTarget.querySelector('svg');
    icon.outerHTML = `<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round">
      <path stroke="none" d="M0 0h24v24H0z" fill="none"></path>
      <path d="M10 14l11 -11"></path>
      <path d="M21 3l-6.5 18a.55 .55 0 0 1 -1 0l-3.5 -7l-7 -3.5a.55 .55 0 0 1 0 -1l18 -6.5"></path>
    </svg>`;
    this.submitButtonTarget.disabled = false;
  }

  handleDataReceived = (event)=> {
    const { data } = event.detail;
    this.appendMessage("assistant", data.content);
    this.saveChatToLocalStorage("assistant", data.content);
  }
}