import { Controller } from "@hotwired/stimulus"

const localStorageKey = "PMWW_ChatHistory"

export default class extends Controller {
    static targets = ["model", "input", "messages"]

    connect() {
        this.restoreChatFromLocalStorage()
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
        const selectedModels = this.modelTargets.filter(checkbox => checkbox.checked).map(checkbox => checkbox.value)
        const userInput = this.inputTarget.value

        const recentMessages = this.getRecentChatHistory(6);

        const data = {
            models: selectedModels,
            user_input: userInput,
            chat_history: recentMessages
        }

        console.log(data)

        this.saveChatToLocalStorage("user", userInput)
        this.appendMessage("user", userInput)
        this.clearInput()

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
                this.saveChatToLocalStorage("assistant", data.content);
            })
            .catch((error) => {
                console.error("Error:", error)
            })
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
        <img class="mr-2 h-8 w-8 rounded-full" src="https://dummyimage.com/128x128/363536/ffffff&text=J" />
        <div class="rounded-b-xl rounded-tr-xl bg-slate-50 p-4 dark:bg-slate-800 sm:max-w-md md:max-w-2xl">
            <p>${message.split("\n\n").join("</p><p>").split("\n").join("<br>")}</p>
        </div>
      `
        }

        this.messagesTarget.appendChild(div)  // 确保你的 HTML 里有 data-thinking-model-target="messages"
    }

    saveChatToLocalStorage(role, content) {
        let chatHistory = JSON.parse(localStorage.getItem(localStorageKey)) || [];

        chatHistory.push({ role, content });

        localStorage.setItem(localStorageKey, JSON.stringify(chatHistory));
    }

    clearInput() {
        this.inputTarget.value = ""
    }
}