import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["fileInput"]

    connect() {
        this.fileInputTarget.addEventListener('change', this.submitForm.bind(this));
    }

    disconnect() {
        this.fileInputTarget.removeEventListener('change', this.submitForm.bind(this));
    }

    submitForm() {
        if (this.fileInputTarget.files.length > 0) {
            this.fileInputTarget.form.submit();
        }
    }
}