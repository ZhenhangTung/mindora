# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "@hotwired--stimulus.js" # @3.2.2
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"
pin "@rails/actioncable", to: "actioncable.esm.js"
# pin "html2pdf", to: "https://cdnjs.cloudflare.com/ajax/libs/html2pdf.js/0.9.3/html2pdf.bundle.min.js"
pin_all_from "app/javascript/channels", under: "channels"
pin "quill" # @1.3.7
pin "buffer" # @2.0.1
pin "@stimulus-components/rails-nested-form", to: "@stimulus-components--rails-nested-form.js" # @5.0.0
pin "@stimulus-components/popover", to: "@stimulus-components--popover.js" # @7.0.0
pin "marked" # @12.0.2
pin "stimulus-textarea-autogrow" # @4.1.0
pin "tailwindcss-stimulus-components" # @5.1.1
pin "async" # @3.2.5
pin "posthog-js" # @1.148.0
