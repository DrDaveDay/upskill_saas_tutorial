import { Controller } from "@hotwired/stimulus"

// Shows only the inputs for the selected game. Hidden fieldsets are disabled
// so their fields aren't submitted.
export default class extends Controller {
  static targets = [ "game", "fields" ]

  connect() { this.switch() }

  switch() {
    const game = this.gameTarget.value
    this.fieldsTargets.forEach((fieldset) => {
      const active = fieldset.dataset.game === game
      fieldset.hidden = !active
      fieldset.disabled = !active
    })
  }
}
