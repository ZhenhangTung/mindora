import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["step", "progressBar"];
    static values = { index: Number }
}