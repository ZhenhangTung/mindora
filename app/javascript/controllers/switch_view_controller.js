import { Controller } from "@hotwired/stimulus"

const localStorageKey = "PMWW_ChatHistory_SwitchView"
const targetUserLocalStorageKey = "PMWW_SwitchView_TargetUser"

export default class extends Controller {
    static targets = ["thoughts", "targetUser", "challenges", "analysisResponse", "analysisButton", "analysisButtonContainer", "messages", "submitButton", "submitButtonContainer", "input"]

    connect() {
        this.restoreChatFromLocalStorage()
        this.loadTargetUser()
    }

    restoreChatFromLocalStorage() {
        let chatHistory = this.getRecentChatHistory(-1);

        chatHistory.forEach(chat => {
            this.appendMessage(chat.role, chat.content);
        });
    }

    submit(event) {
        event.preventDefault()
        const userInput = `产品想法：${this.thoughtsTarget.value}\n目标用户：${this.targetUserTarget.value}\n当下挑战：${this.challengesTarget.value}\n`
        const data = {
            models: ["用户体验地图"],
            instructions: "在用户体验地图的每个关键点（用户目标、行为、接触点、情绪与想法、痛点、机会点）上给出你的分析供参考。最后提供 3 个参考解决方案的时候，要求同时提供解决方案和设计此方案的原因。",
            user_input: userInput,
            chat_history: []
        }
        this.disableSubmitButton()
        this.disableAnalysisButton()

        this.saveChatToLocalStorage("user", userInput)
        this.appendMessage("user", userInput)

        console.log(data)

        fetch("/chat/thinking_models", {
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
                this.saveChatToLocalStorage("assistant", data.content)
                this.hideAnalysisButtonContainer()
                this.displaySubmitButtonContainer()
            })
            .catch((error) => {
                console.error("Error:", error)
                alert("发生错误:", error)
            }).finally(() => {
                this.enableAnalysisButton()
                this.enableSubmitButton()
            });

    }

    getRecentChatHistory(count = 10) {
        let chatHistory = JSON.parse(localStorage.getItem(localStorageKey)) || [];

        return count > 0 ? chatHistory.slice(-count) : chatHistory;
    }

    chat(event) {
        event.preventDefault()
        this.disableSubmitButton()

        const userInput = this.inputTarget.value

        const recentMessages = this.getRecentChatHistory(10);

        const data = {
            user_input: userInput,
            chat_history: recentMessages
        }

        console.log(data)

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
            this.enableSubmitButton()
        });
    }

    saveChatToLocalStorage(role, content) {
        let chatHistory = JSON.parse(localStorage.getItem(localStorageKey)) || [];

        chatHistory.push({ role, content });

        localStorage.setItem(localStorageKey, JSON.stringify(chatHistory));
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

    clearInput() {
        this.inputTarget.value = ""
    }

    scrollToBottom() {
        const messagesContainer = this.messagesTarget;
        messagesContainer.scrollTop = messagesContainer.scrollHeight;
    }

    disableAnalysisButton() {
        const button = this.analysisButtonTarget
        button.classList.add('cursor-not-allowed', 'animate-bounce');
        button.setAttribute('disabled', true);
    }

    enableAnalysisButton() {
        const button = this.analysisButtonTarget
        button.classList.remove('cursor-not-allowed', 'animate-bounce');
        button.removeAttribute('disabled');
    }

    disableSubmitButton() {
        const icon = this.submitButtonTarget.querySelector('svg');
        icon.outerHTML = `<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-6">
      <path stroke-linecap="round" stroke-linejoin="round" d="M6.75 12a.75.75 0 1 1-1.5 0 .75.75 0 0 1 1.5 0ZM12.75 12a.75.75 0 1 1-1.5 0 .75.75 0 0 1 1.5 0ZM18.75 12a.75.75 0 1 1-1.5 0 .75.75 0 0 1 1.5 0Z" />
    </svg>`;
        this.submitButtonTarget.disabled = true;
    }

    enableSubmitButton() {
        const icon = this.submitButtonTarget.querySelector('svg');
        icon.outerHTML = `<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round">
      <path stroke="none" d="M0 0h24v24H0z" fill="none"></path>
      <path d="M10 14l11 -11"></path>
      <path d="M21 3l-6.5 18a.55 .55 0 0 1 -1 0l-3.5 -7l-7 -3.5a.55 .55 0 0 1 0 -1l18 -6.5"></path>
    </svg>`;
        this.submitButtonTarget.disabled = false;
    }

    hideAnalysisButtonContainer() {
        this.analysisButtonContainerTarget.classList.add("hidden")
    }

    displaySubmitButtonContainer() {
        this.submitButtonContainerTarget.classList.remove("hidden")
    }

    saveTargetUser(event) {
        const value = this.targetUserTarget.value;
        localStorage.setItem(targetUserLocalStorageKey, value);
    }

    loadTargetUser(event) {
        const value = localStorage.getItem(targetUserLocalStorageKey);
        if (value) {
            this.targetUserTarget.value = value;
        }
    }

}