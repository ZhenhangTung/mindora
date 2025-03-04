import { Controller } from "@hotwired/stimulus"
import { marked } from "marked"

export default class extends Controller {
    static values = { productId: Number }
    static targets = ["assumptions", "messages", "submitButton"]

    connect() {
        console.log(this.productIdValue)
    }

    submit(event) {
        event.preventDefault()

        if (!this.assumptionsTarget.value) {
            alert("请填写需求假设")
        }

        const data = {
            assumptions: this.assumptionsTarget.value,
        }
        this.disableSubmitButton()

        fetch(`/works/products/${this.productIdValue}/user_interview_questions`, {
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
            })
            .catch((error) => {
                console.error("Error:", error)
                alert("发生错误:", error)
            }).finally(() => {
                this.enableSubmitButton()
            });
    }

    disableSubmitButton() {
        const button = this.submitButtonTarget
        button.classList.add('cursor-not-allowed', 'animate-bounce');
        button.setAttribute('disabled', true);
    }

    enableSubmitButton() {
        const button = this.submitButtonTarget
        button.classList.remove('cursor-not-allowed', 'animate-bounce');
        button.removeAttribute('disabled');
    }

    appendMessage(role, message) {
        const div = document.createElement("div")
        div.classList.add("flex", "items-start")
        const parsedMessage = marked(message);

        if (role === "user") {
            div.classList.add("flex-row-reverse")
            div.innerHTML = `
        <img class="ml-2 h-8 w-8 rounded-full" src="https://dummyimage.com/128x128/354ea1/ffffff&text=我" />
        <div class="min-h-[85px] rounded-b-xl rounded-tl-xl bg-indigo-50 p-4 dark:bg-indigo-800 sm:min-h-0 sm:max-w-md md:max-w-2xl">
            <p>${parsedMessage}</p>
        </div>
      `
        } else {  // assistant
            div.innerHTML = `
        <img class="mr-2 h-8 w-8 rounded-full" src="https://dummyimage.com/128x128/363536/ffffff&text=汪" />
        <div class="rounded-b-xl rounded-tr-xl bg-slate-50 p-4 dark:bg-slate-800 sm:max-w-md md:max-w-2xl">
            <p>${parsedMessage}</p>
        </div>
      `
        }

        this.messagesTarget.appendChild(div)  // 确保你的 HTML 里有 data-thinking-model-target="messages"
    }
}