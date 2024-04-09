import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["model", "input"]

    connect() {
        this.loadMessages()
    }

    loadMessages() {

    }

    submit(event) {
        const selectedModels = this.modelTargets.filter(checkbox => checkbox.checked).map(checkbox => checkbox.value)
        const userInput = this.inputTarget.value

        const data = {
            models: selectedModels,
            user_input: userInput
        }

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
                // 处理响应数据
            })
            .catch((error) => {
                console.error("Error:", error)
            })
    }

    sendMessage(message) {

    }

    addMessage(content) {

    }
}