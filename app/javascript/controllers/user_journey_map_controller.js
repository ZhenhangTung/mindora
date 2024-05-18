import { Controller } from "@hotwired/stimulus";
import consumer from "../channels/consumer";
import { marked } from "marked";

export default class extends Controller {
    static values = { userJourneyMapId: Number }
    static targets = ["messages"]

    connect() {
        this.channel = consumer.subscriptions.create(
            { channel: "UserJourneyMapChannel", user_journey_map_id: this.userJourneyMapIdValue },
            {
                received: this.handleReceived.bind(this)
            }
        );
        this.scrollToBottom();
    }

    handleReceived(data) {
        const { type, content, uuid } = data;
        const existingMessage = document.querySelector(`[data-uuid='${uuid}']`);

        if (existingMessage) {
            this.updateMessage(existingMessage, content);
        } else {
            this.appendMessage(type, content, uuid);
        }
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
        this.scrollToBottom();
    }

    updateMessage(element, content) {
        // Append the new content to the original content
        const originalContent = element.querySelector('p').innerHTML;
        const newContent = originalContent + content;

        // Update the element with the combined content using marked
        element.querySelector('p').innerHTML = marked(newContent);
    }

    scrollToBottom() {
        const messagesContainer = this.messagesTarget;
        messagesContainer.scrollTop = messagesContainer.scrollHeight;
    }
}