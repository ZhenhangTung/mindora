import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["container", "pagination", "nextButton", "prevButton"];

    connect() {
        // Initialize Swiper
        new Swiper(this.containerTarget, {
            loop: true,
            pagination: {
                el: this.paginationTarget,
                clickable: true
            },
            navigation: {
                nextEl: this.nextButtonTarget,
                prevEl: this.prevButtonTarget
            }
        });
    }
}