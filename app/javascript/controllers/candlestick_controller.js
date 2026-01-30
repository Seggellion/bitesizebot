import { Controller } from "@hotwired/stimulus"
import { Chart } from "chart.js"

export default class extends Controller {
  static values = {
    data: Array
  }

  connect() {
    console.log('hello world');

    const ctx = this.element.getContext("2d")

const data = this.dataValue
  .filter(([t, o, h, l, c]) => o !== null)
  .map(([t, o, h, l, c]) => ({
    x: new Date(t),
    o, h, l, c
  }))

if (data.length === 0) return

this.chart = new Chart(ctx, {
      type: "candlestick",
      data: {
        datasets: [{
          label: "Price",
          data: data,
          // Add these to fix the "thick" look
          barThickness: 8, 
          categoryPercentage: 0.9,
          barPercentage: 0.9
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false, // Essential for the container height
        scales: {
          x: {
            type: "timeseries",
            offset: true, // Adds space at the edges so candles don't hit the Y-axis
            ticks: {
              maxRotation: 0,
              autoSkip: true
            }
          },
          y: {
            beginAtZero: false, // Don't start at $0 for a $500 stock!
            grace: '5%',       // Adds a little "breathing room" top and bottom
            position: 'right'   // Standard trading view style
          }
        },
        plugins: {
          legend: { display: false } // Cleans up the UI
        }
      }
    })

    
  }

  disconnect() {
    this.chart?.destroy()
  }
}
