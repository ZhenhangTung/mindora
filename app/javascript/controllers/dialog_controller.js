import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["dialog", "backdrop", "modal", "form"]

    connect() {
        // Ensure the dialog is hidden when the controller is connected
        this.hideDialog();
    }

    showDialog() {
        this.dialogTarget.classList.remove("hidden");
        this.backdropTarget.classList.add("ease-out", "duration-300", "opacity-100");
        this.backdropTarget.classList.remove("ease-in", "duration-200", "opacity-0");
        this.modalTarget.classList.add("ease-out", "duration-300", "opacity-100", "translate-y-0", "sm:scale-100");
        this.modalTarget.classList.remove("ease-in", "duration-200", "opacity-0", "translate-y-4", "sm:translate-y-0", "sm:scale-95");
    }

    hideDialog() {
        this.dialogTarget.classList.add("hidden");
        this.backdropTarget.classList.add("ease-in", "duration-200", "opacity-0");
        this.backdropTarget.classList.remove("ease-out", "duration-300", "opacity-100");
        this.modalTarget.classList.add("ease-in", "duration-200", "opacity-0", "translate-y-4", "sm:translate-y-0", "sm:scale-95");
        this.modalTarget.classList.remove("ease-out", "duration-300", "opacity-100", "translate-y-0", "sm:scale-100");
    }
}