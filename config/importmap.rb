# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "@rails/ujs", to: "https://cdn.jsdelivr.net/npm/@rails/ujs@7.1.3-4/app/assets/javascripts/rails-ujs.min.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "trix"
pin "leaflet", to: "https://ga.jspm.io/npm:leaflet@1.9.4/dist/leaflet-src.js"
pin "@rails/actiontext", to: "actiontext.esm.js"
pin "canvas-confetti" # @1.9.4

pin "chartkick", to: "chartkick.js"

pin "chart.js", to: "https://ga.jspm.io/npm:chart.js@4.4.1/dist/chart.js"
pin "chart.js/helpers", to: "https://ga.jspm.io/npm:chart.js@4.4.1/helpers/helpers.js"
pin "@kurkle/color", to: "https://ga.jspm.io/npm:@kurkle/color@0.3.2/dist/color.esm.js"

pin "date-fns", to: "https://ga.jspm.io/npm:date-fns@3.6.0/index.mjs"
pin "chartjs-adapter-date-fns", to: "https://ga.jspm.io/npm:chartjs-adapter-date-fns@3.0.0/dist/chartjs-adapter-date-fns.esm.js"
pin "chartjs-chart-financial", to: "https://ga.jspm.io/npm:chartjs-chart-financial@0.2.1/dist/chartjs-chart-financial.esm.js"