import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["submenu", "parent", "arrow"];

    connect() {
        // Call toggleExpanded to check which submenus should be expanded initially
        this.toggleExpanded();
    }

    toggle(event) {
        event.preventDefault();
        const parent = event.currentTarget;
        const submenu = parent.nextElementSibling;

        if (submenu.classList.contains('hidden')) {
            submenu.classList.remove('hidden');
        } else {
            submenu.classList.add('hidden');
        }

        // Optionally, toggle the arrow icon rotation
        this.arrowTarget.classList.toggle('rotate-180');
    }

    toggleExpanded() {
        const currentPath = window.location.pathname;
        this.submenuTargets.forEach(submenu => {
            const links = submenu.querySelectorAll('a');
            links.forEach(link => {
                if (link.getAttribute('href') === currentPath) {
                    submenu.classList.remove('hidden');
                }
            });
        });
    }
}