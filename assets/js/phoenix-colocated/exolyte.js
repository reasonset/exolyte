let Hooks = {}
let SoundBipo
let SoundBipi
let SoundChi

Hooks.AutoResize = {
  mounted() {
    this.el.addEventListener("input", () => {
      this.el.style.height = "auto"
      this.el.style.height = this.el.scrollHeight + "px"
    })
  }
}

Hooks.ChatContainerHook = {
  mounted() {
    if (this.el.scrollHeight <= this.el.clientHeight) {
      this.pushEvent("load_more", {}, () => {
        this.el.scrollTop = this.el.scrollHeight
      })
    }

    this.el.scrollTop = this.el.scrollHeight

    this.el.addEventListener("scroll", e => {
      const prevHeight = this.el.scrollHeight
      const prevTop = this.el.scrollTop
      if (this.el.scrollTop === 0 && this.el.dataset.hasMore === "true" && (this.el.dataset.oldestIndex || 0) > 1) {
        this.pushEvent("load_more", {}, () => {
          const newHeight = this.el.scrollHeight
          this.el.scrollTop = prevTop + (newHeight - prevHeight)
        })
      }
    })

    this.handleEvent("sound_receive", () => {
      if (SoundBipo) {
        if (document.hidden) {
          SoundBipo.play()
        } else {
          SoundChi.play()
        }
      }
    })
    this.handleEvent("sound_sent", () => {
      if (SoundBipi) {
        SoundBipi.play()
      }
    })
  },
  updated() {
    const nearBottom = this.el.scrollHeight - this.el.scrollTop - this.el.clientHeight < (this.el.clientHeight / 2)
    if (nearBottom) {
      this.el.scrollTop = this.el.scrollHeight
    }
  }
}

Hooks.Keybinds = {
  mounted() {
    const form = this.el
    const textarea = form.querySelector('textarea')

    const submit = () => form.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))

    textarea.addEventListener('keydown', (e) => {
      if (e.isComposing) {return}

      const ctrlEnter = (e.ctrlKey && e.key === 'Enter')
      const cmdEnter  = (e.metaKey && e.key === 'Enter') // macOS
      const shiftEnter = (e.shiftKey && e.key === 'Enter')

      if (shiftEnter) {
        return
      }

      if (ctrlEnter || cmdEnter) {
        e.preventDefault()
        submit()
        return
      }
    })
  }
}

window.addEventListener("click", e => {
  if (!SoundBipo) {
    SoundBipo = new Audio("/notification_sound.ogg")
    SoundChi = new Audio("/notification_foreground_sound.ogg")
    SoundBipi = new Audio("/sending_sound.ogg")
  }
})

export {Hooks as hooks}
