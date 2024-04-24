import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["scene", "challenge"]

    submitChallenge(event) {
        event.preventDefault()

        const scene = this.sceneTarget.textContent.trim(); // 获取场景文本

        const buttonElement = event.currentTarget;
        let challenge = buttonElement.dataset.value;
        if (!challenge) {
            // 如果 data-value 为空，退回到使用按钮文本
            challenge = buttonElement.textContent.trim();
        }


        event.target.classList.add('cursor-not-allowed', 'animate-bounce');
        event.target.setAttribute('disabled', true);

        const data = { scene, challenge };
        fetch("/chat/challenges", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").getAttribute("content")
            },
            body: JSON.stringify(data)
        })
            .then(response => response.json())
            .then(data => {
                const event = new CustomEvent("chat-data-received", {
                    detail: { data }, // 将数据包装在detail属性中
                    bubbles: true, // 事件冒泡
                });
                this.element.dispatchEvent(event);
            })
            .catch((error) => {
                console.error("Error:", error);
            })
            .finally(() => {
                event.target.classList.remove('cursor-not-allowed', 'animate-bounce');
                event.target.removeAttribute('disabled');
            });
    }
}