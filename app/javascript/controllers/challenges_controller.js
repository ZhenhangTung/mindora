import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["scene", "challenge"]

    submitChallenge(event) {
        event.preventDefault()

        const scene = this.sceneTarget.textContent.trim(); // 获取场景文本
        const challenge = event.target.textContent.trim(); // 获取按钮的文本

        console.log(scene)
        console.log(challenge)

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
                console.log("Success:", data);
                const event = new CustomEvent("chat-data-received", {
                    detail: { data }, // 将数据包装在detail属性中
                    bubbles: true, // 事件冒泡
                });
                this.element.dispatchEvent(event);
            })
            .catch((error) => {
                console.error("Error:", error);
            });
    }
}