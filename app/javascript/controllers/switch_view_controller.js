import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["thoughts", "targetUser", "challenges", "analysisResponse", "analysisButton"]

    submit(event) {
        event.preventDefault()
        const data = {
            models: ["切换至用户视角分析问题"],
            user_input: `产品想法和背景：${this.thoughtsTarget.value}；目标用户：${this.targetUserTarget.value}，用户挑战：${this.challengesTarget.value}`,
            chat_history: []
        }
        const button = this.analysisButtonTarget
        button.classList.add('cursor-not-allowed', 'animate-bounce');
        button.setAttribute('disabled', true);

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
                const content = data.content
                this.analysisResponseTarget.innerHTML = `<p>${content.split("\n\n").join("</p><p>").split("\n").join("<br>")}</p>`
            })
            .catch((error) => {
                console.error("Error:", error)
                alert("发生错误:", error)
            }).finally(() => {
                button.classList.remove('cursor-not-allowed', 'animate-bounce');
                button.removeAttribute('disabled');
            });

    }
}