import { Controller } from "@hotwired/stimulus";
import consumer from "channels/consumer";
export default class extends Controller {
    static targets = ["status"]
    static values = { resumeId: Number }

    connect() {
        this.channel = consumer.subscriptions.create(
            { channel: "ResumeStatusChannel", resume_id: this.resumeIdValue },
            {
                received: this.received.bind(this)
            }
        );
    }

    received(data) {
        this.updateStatus(data.status, data.message);
        if (data.status === "completed") {
            this.updateProgressBar(100);
            window.location.reload(); // Refresh the page to show updated resume details
        } else if (data.status === "failed") {
            // TODO: improve me
            document.getElementById("progress-bar-container").classList.add("hidden")
        }
    }

    updateStatus(status, message) {
        this.statusTarget.innerText = message;
    }

    updateProgressBar(percentage) {
        const progressBarController = this.application.getControllerForElementAndIdentifier(
            document.querySelector('[data-controller="progress-bar"]'),
            "progress-bar"
        );

        if (progressBarController) {
            progressBarController.updateProgress(percentage);
        }
    }
}