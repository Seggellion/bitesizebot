// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "@rails/ujs"

import "controllers"

import "trix"
import "@rails/actiontext"



// 1. Import Chart.js and its components
import { Chart, registerables } from "chart.js"
import { CandlestickController, CandlestickElement } from "chartjs-chart-financial" // Add this
import "chartjs-adapter-date-fns"
    
Chart.register(...registerables, CandlestickController, CandlestickElement)

// 2. Register the components (Lines, Bars, etc.)

// 3. Import Chartkick for "side effects" only
// (This runs the script and creates 'window.Chartkick')
import "chartkick"


// 4. Manually link them using the global variable
window.Chartkick.use(Chart)