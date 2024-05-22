import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["progressBar", "progressText"]
    static values = { duration: Number, startTime: String }

    connect() {
        this.startProgress();
    }

    startProgress() {
        const startTime = new Date(this.startTimeValue);
        const currentTime = new Date();
        const elapsedTime = currentTime - startTime;
        const totalDuration = this.durationValue;

        let progress = Math.min((elapsedTime / totalDuration) * 100, 100);

        this.updateProgress(progress);

        const remainingTime = totalDuration - elapsedTime;
        if (remainingTime > 0) {
            const intervalDuration = remainingTime / (100 - progress);
            this.interval = setInterval(() => {
                progress += 1;
                this.updateProgress(progress);
                if (progress >= 100) {
                    clearInterval(this.interval);
                }
            }, intervalDuration);
        }
    }

    updateProgress(progress) {
        const progressPercentage = `${progress.toFixed(2)}%`;
        this.progressBarTarget.style.width = progressPercentage;
        this.progressTextTarget.textContent = progressPercentage;
    }
}