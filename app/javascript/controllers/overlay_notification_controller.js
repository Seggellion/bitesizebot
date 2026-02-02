// app/javascript/controllers/overlay_notification_controller.js
import { Controller } from "@hotwired/stimulus"
import confetti from "canvas-confetti"

export default class extends Controller {
  static values = { 
    duration: { type: Number, default: 10000 },
    confetti: { type: Boolean, default: false }
  }

  connect() {
    // Fire confetti if this is a win notification
    if (this.confettiValue) {
      this.fireConfetti()
    }

    // Standard cleanup logic
    setTimeout(() => {
      this.element.style.opacity = "0"
      setTimeout(() => this.element.remove(), 1200)
    }, this.durationValue)
  }

  fireConfetti() {
    const duration = 10 * 1000;
    const animationEnd = Date.now() + duration;
    const defaults = { startVelocity: 30, spread: 360, ticks: 60, zIndex: 0 };

    const randomInRange = (min, max) => Math.random() * (max - min) + min;

    const interval = setInterval(function() {
      const timeLeft = animationEnd - Date.now();

      if (timeLeft <= 0) {
        return clearInterval(interval);
      }

      const particleCount = 50 * (timeLeft / duration);
      
      // Since it's for OBS, we fire from two sides for a cinematic look
      confetti({ ...defaults, particleCount, origin: { x: randomInRange(0.1, 0.3), y: Math.random() - 0.2 } });
      confetti({ ...defaults, particleCount, origin: { x: randomInRange(0.7, 0.9), y: Math.random() - 0.2 } });
    }, 250);
  }
}