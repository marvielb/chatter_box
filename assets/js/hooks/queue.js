/**
 * @type {import("phoenix_live_view").ViewHook}
 */
let Hooks = {};
Hooks.Queue = {
  async mounted() {
    let userId = localStorage.getItem("user_id");
    if (!userId) {
      userId = crypto.randomUUID();
      localStorage.setItem("user_id", userId);
    }
    //Wait for the camera to be ready before joining the queue
    await navigator.mediaDevices.getUserMedia({
      video: true,
      audio: true,
    });

    this.pushEvent("join", { user_id: userId });
  },
};

export default Hooks;
