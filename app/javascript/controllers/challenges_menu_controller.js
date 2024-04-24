import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["dailyComm", "sideProj", "dailyCommContent", "sideProjContent"]

    toggleContent(event) {
        event.preventDefault();
        const buttonTarget = event.currentTarget.getAttribute('data-challenges-menu-target');

        this.dailyCommContentTarget.classList.toggle('hidden', buttonTarget !== 'dailyComm');
        this.sideProjContentTarget.classList.toggle('hidden', buttonTarget !== 'sideProj');
    }
}