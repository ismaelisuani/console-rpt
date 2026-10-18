import { Controller } from "@hotwired/stimulus"

// Light or dark theme: switches at once, and is kept for the user (and in this
// browser, for the sign-in page)
export default class extends Controller {
  static values = { url: String }

  toggle() {
    const root = document.documentElement
    const theme = root.dataset.theme === "light" ? "dark" : "light"
    root.dataset.theme = theme
    document.cookie = `theme=${theme}; path=/; max-age=31536000; SameSite=Lax`
    if (!this.urlValue) return
    fetch(this.urlValue, {
      method: "PATCH",
      headers: { "Content-Type": "application/json", "Accept": "application/json",
        "X-CSRF-Token": document.querySelector("meta[name=csrf-token]")?.content },
      body: JSON.stringify({ user: { theme } })
    })
  }
}
