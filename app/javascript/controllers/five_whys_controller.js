import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["step", "progressBar", "textarea", "promptDisplay", "stepDescription", "previousButton", "nextButton"];
    static values = { index: Number }

    stepData = {};

    connect() {
        this.indexValueChanged();
    }

    next(event) {
        event.preventDefault();
        // Get the current textarea within the active step
        const currentTextarea = this.stepTargets[this.indexValue].querySelector('textarea');
        // Check if the textarea is filled
        if (currentTextarea.value.trim() === '') {
            // Handle the case where the textarea is empty
            // For example, alert the user or add a validation message
            alert('请填入内容再点击下一步。');
            return; // Stop the function from proceeding to the next step
        }

        this.saveCurrentStepData(); // Save data before moving to next step

        if (this.indexValue < this.stepTargets.length - 1) {
            this.indexValue++;
        }

        this.submitData(); // Submit data and update view based on the backend response
    }

    previous() {
        if (this.indexValue > 0) {
            this.indexValue--;
        }
    }

    indexValueChanged() {
        this.updateSteps();
        this.updateNavigationButtons();
    }

    updateSteps() {
        this.stepTargets.forEach((el, index) => {
            const isDisabled = index !== this.indexValue;
            el.classList.toggle("cursor-not-allowed", isDisabled);
            el.classList.toggle("opacity-50", isDisabled);

            // Find the textarea within the current step and disable or enable it
            const textarea = el.querySelector("textarea");
            if (textarea) {
                textarea.disabled = isDisabled;
            }
        });
        const progressWidth = ((this.indexValue + 1) / this.stepTargets.length) * 100;
        this.progressBarTarget.style.width = `${progressWidth}%`;
    }

    updateNavigationButtons() {
        const previousButton = this.previousButtonTarget;
        const nextButton = this.nextButtonTarget;
        const lastIndex = this.stepTargets.length - 1;

        // 启用或禁用“上一步”按钮
        if (this.indexValue === 0) {
            previousButton.classList.add('hidden');
        } else {
            previousButton.classList.remove('hidden');
        }

        // 启用或禁用“下一步”按钮
        if (this.indexValue === lastIndex) {
            nextButton.classList.add('hidden');
        } else {
            nextButton.classList.remove('hidden');
        }
    }

    saveCurrentStepData() {
        const stepKeys = ['who', 'what', 'when', 'where', 'why', 'how'];
        const currentTextarea = this.textareaTargets[this.indexValue];
        if (currentTextarea) {
            this.stepData[stepKeys[this.indexValue]] = currentTextarea.value;
        }
    }

    submitData() {
        console.log(this.stepData)
        fetch("/chat/thinking_models/five_whys", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").getAttribute("content")
            },
            body: JSON.stringify({ form_data: this.stepData })
        })
            .then(response => response.json())
            .then(data => {
                // Process and display data from the server
                console.log("Server response:", data);
                this.updateNextStepDescription(data.content);
            })
            .catch(error => console.error("Error:", error));
    }

    updateNextStepDescription(message) {
        const currentIndex = this.indexValue;
        const nextStepElement = this.stepTargets[currentIndex]; // Assuming there is a next step
        if (nextStepElement) {
            const descriptionElement = nextStepElement.querySelector("[data-five-whys-target='stepDescription']");
            if (descriptionElement) {
                descriptionElement.innerText = `🐶：${message}`;
            }
        }
    }
}