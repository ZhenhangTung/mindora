import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["overlay", "panel"];

    connect() {
        // Initialize the slide-over to be hidden
        this.hide();
    }

    show() {
        this.overlayTarget.classList.remove('hidden');
        this.panelTarget.classList.remove('translate-x-full');
    }

    hide() {
        this.overlayTarget.classList.add('hidden');
        this.panelTarget.classList.add('translate-x-full');
    }
}