import { Controller } from "@hotwired/stimulus";
import consumer from "channels/consumer";
import { marked } from "marked";
import async from "async";

export default class extends Controller {
    static values = { sessionId: String }
    static targets = ["messages", "chatInput", "chatButton"]

    connect() {
        this.channel = consumer.subscriptions.create(
            { channel: "SessionChannel", session_id: this.sessionIdValue },
            {
                connected: () => {
                    console.log("Connected to SessionChannel");
                },
                disconnected: () => {
                    console.log("Disconnected from SessionChannel");
                },
                received: this.handleReceived.bind(this)
            }
        );
        this.scrollToBottom();

        // 创建一个异步队列，限制并发数为1
        this.messageQueue = async.queue((task, callback) => {
            this.processMessage(task.data);
            setTimeout(callback, 50); // 处理完成后延迟50ms，避免竞争条件
        }, 1); // 限制并发数为1
    }

    handleReceived(data) {
        this.messageQueue.push({ data });
    }

    processMessage(data) {
        const existingMessage = document.querySelector(`[data-uuid="${data.uuid}"]`);

        if (existingMessage) {
            this.updateMessage(existingMessage, data.content);
        } else {
            this.appendMessage(data.type, data.content, data.uuid);
        }

        this.scrollToBottom();
    }

    disconnect() {
        if (this.channel) {
            this.channel.unsubscribe();
        }
    }

    appendMessage(type, message, uuid) {
        const div = document.createElement("div")
        div.classList.add("flex", "items-start")
        div.dataset.uuid = uuid;
        const parsedMessage = marked(message);

        if (type === "human") {
            div.classList.add("flex-row-reverse")
            div.innerHTML = `
        <img class="ml-2 h-8 w-8 rounded-full" src="https://dummyimage.com/128x128/354ea1/ffffff&text=我" />
        <div class="min-h-[85px] rounded-b-xl rounded-tl-xl bg-indigo-50 p-4 dark:bg-indigo-800 sm:min-h-0 sm:max-w-md md:max-w-2xl">
            <p data-original-content="${message}">${parsedMessage}</p>
        </div>
      `
        } else {  // assistant
            div.innerHTML = `
        <img class="mr-2 h-8 w-8 rounded-full" src="https://dummyimage.com/128x128/363536/ffffff&text=汪" />
        <div class="rounded-b-xl rounded-tr-xl bg-slate-50 p-4 dark:bg-slate-800 sm:max-w-md md:max-w-2xl">
            <p data-original-content="${message}">${parsedMessage}</p>
        </div>
      `
        }

        this.messagesTarget.appendChild(div)
    }

    updateMessage(element, content) {
        // Append the new content to the original content
        const originalContent = element.querySelector('p').dataset.originalContent || "";
        const newContent = originalContent + content;

        // Update the data-original-content attribute with the combined content
        element.querySelector('p').dataset.originalContent = newContent;

        // Update the element with the combined content using marked
        element.querySelector('p').innerHTML = marked(newContent);
    }

    scrollToBottom() {
        const messagesContainer = this.messagesTarget;
        messagesContainer.style.scrollBehavior = "smooth";
        messagesContainer.scrollTop = messagesContainer.scrollHeight;

        // restore the behavior
        setTimeout(() => {
            messagesContainer.style.scrollBehavior = "auto";
        }, 500);
    }

    chat(event) {
        event.preventDefault();
        const inputElement = this.chatInputTarget;
        const message = inputElement.value.trim();

        if (message === "") {
            return;
        }

        const formElement = event.target.closest("form");
        const formData = new FormData(formElement);
        const url = formElement.action;

        // Send the message via AJAX
        fetch(url, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").getAttribute("content")
            },
            body: JSON.stringify({ message: { content: message } })
        })
            .then(response => response.json())
            .then(data => {
                if (data.status === "Message received") {
                    this.resetInput()
                }
            })
            .catch((error) => {
                console.error("Error:", error)
                alert("发生错误:", error)
            })
            .finally(() => {
                this.scrollToBottom()
            });
    }

    disableSubmitButton() {
        const icon = this.chatButtonTarget.querySelector('svg');
        icon.outerHTML = `<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-6">
      <path stroke-linecap="round" stroke-linejoin="round" d="M6.75 12a.75.75 0 1 1-1.5 0 .75.75 0 0 1 1.5 0ZM12.75 12a.75.75 0 1 1-1.5 0 .75.75 0 0 1 1.5 0ZM18.75 12a.75.75 0 1 1-1.5 0 .75.75 0 0 1 1.5 0Z" />
    </svg>`;
        this.chatButtonTarget.disabled = true;
    }

    enableSubmitButton() {
        const icon = this.chatButtonTarget.querySelector('svg');
        icon.outerHTML = `<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round">
      <path stroke="none" d="M0 0h24v24H0z" fill="none"></path>
      <path d="M10 14l11 -11"></path>
      <path d="M21 3l-6.5 18a.55 .55 0 0 1 -1 0l-3.5 -7l-7 -3.5a.55 .55 0 0 1 0 -1l18 -6.5"></path>
    </svg>`;
        this.chatButtonTarget.disabled = false;
    }

    resetInput() {
        this.chatInputTarget.style.height = 'auto';
        this.chatInputTarget.value = '';
    }
}