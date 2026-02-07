import { Controller } from "@hotwired/stimulus"
import { Chart } from "chart.js"

export default class extends Controller {
  static values = { data: Array }

  connect() {
    const ctx = this.element.getContext("2d")
    const data = this.dataValue
      .filter(([t, o, h, l, c]) => o !== null)
      .map(([t, o, h, l, c]) => ({
        x: new Date(t).getTime(), // Use timestamp for better performance
        o, h, l, c
      }))

    if (data.length === 0) return

    this.chart = new Chart(ctx, {
      type: "candlestick",
      data: {
        datasets: [{
          label: "Price",
          data: data,
          barThickness: 'flex', // Better for zooming than a fixed pixel value
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          x: {
            type: "timeseries", // This collapses weekends/gaps
            display: true,
            ticks: {
              source: 'data', // Important: only show ticks for data points that exist
              maxRotation: 0,
              autoSkip: true
            }
          },
          y: {
            position: 'right',
            beginAtZero: false
          }
        },
        plugins: {
          legend: { display: false },
          zoom: {
            zoom: {
              wheel: { enabled: true }, // Zoom with mouse wheel
              pinch: { enabled: true }, // Zoom with fingers on mobile
              mode: 'x',               // Only zoom the time axis
            },
            pan: {
              enabled: true,
              mode: 'x',               // Only pan left/right
            }
          }
        }
      }
    })
  }

  disconnect() {
    this.chart?.destroy()
  }
}