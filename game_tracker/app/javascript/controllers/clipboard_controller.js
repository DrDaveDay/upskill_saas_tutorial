import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "source", "button" ]

  async copy() {
    try {
      await navigator.clipboard.writeText(this.sourceTarget.value)
    } catch {
      this.sourceTarget.select()
      document.execCommand("copy")
    }
    this.flash("Copied!")
  }

  async paste() {
    try {
      const text = await navigator.clipboard.readText()
      const current = this.sourceTarget.value.trim()
      this.sourceTarget.value = current ? `${current}\n\n${text}` : text
      this.flash("Pasted!")
    } catch {
      this.sourceTarget.focus()
      this.flash("Long-press to paste")
    }
  }

  flash(message) {
    if (!this.hasButtonTarget) return
    const original = this.buttonTarget.textContent
    this.buttonTarget.textContent = message
    setTimeout(() => this.buttonTarget.textContent = original, 1500)
  }
}
