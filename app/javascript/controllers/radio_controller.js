import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["label", "input"];

    connect() {
        this.updateRadioStyles();
        this.prevInput = null;
    }

    select(event) {
        const selectedInput = event.currentTarget;

        // Uncheck all other radio buttons in the group
        this.inputTargets.forEach(input => {
            input.checked = false;
            input.closest('label').classList.remove("border-indigo-600", "ring-2", "ring-indigo-600");
            input.closest('label').classList.add("border-gray-300");
        });

        if (this.prevInput !== selectedInput) {
            // Check the clicked radio button
            selectedInput.checked = true;
            selectedInput.closest('label').classList.add("border-indigo-600", "ring-2", "ring-indigo-600");
            selectedInput.closest('label').classList.remove("border-gray-300");
            this.prevInput = selectedInput;
        } else {
            this.prevInput = null;
        }
    }

    updateRadioStyles() {
        this.inputTargets.forEach(input => {
            if (input.checked) {
                input.closest('label').classList.add("border-indigo-600", "ring-2", "ring-indigo-600");
                input.closest('label').classList.remove("border-gray-300");
            } else {
                input.closest('label').classList.add("border-gray-300");
            }
        });
    }
}