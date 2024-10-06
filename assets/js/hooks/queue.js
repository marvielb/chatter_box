/**
 * @type {import("phoenix_live_view").ViewHook}
 */
let Hooks = {}
Hooks.UserID = {
  mounted() {
    let userId = localStorage.getItem('user_id')
    if(!userId) {
      userId = crypto.randomUUID()  
      localStorage.setItem('user_id', userId)
    }
    this.pushEvent('join', {user_id: userId})
  }
}

export default Hooks
