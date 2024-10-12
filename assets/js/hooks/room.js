let localStream = null;
let remoteStream = null;
const servers = {
  iceServers: [
    {
      urls: ["stun:stun1.l.google.com:19302", "stun:stun2.l.google.com:19302"],
    },
  ],
  iceCandidatePoolSize: 10,
};

const pc = new RTCPeerConnection(servers);
/**
 * @type {import("phoenix_live_view").ViewHook}
 */
let Hooks = {};
Hooks.Webcam = {
  async mounted() {
    this.handleEvent("create_offer", async () => {
      const offerDescription = await pc.createOffer();
      await pc.setLocalDescription(offerDescription);

      const offer = {
        sdp: offerDescription.sdp,
        type: offerDescription.type,
      };
      this.pushEvent("offer_info", offer);
    });
    this.handleEvent("handle_offer", async (offer) => {
      console.log("handling_offer..");
      await pc.setRemoteDescription(new RTCSessionDescription(offer));

      const answerDescription = await pc.createAnswer();
      await pc.setLocalDescription(answerDescription);

      const answer = {
        type: answerDescription.type,
        sdp: answerDescription.sdp,
      };
      console.log("answer", answer);
    });

    let userId = localStorage.getItem("user_id");
    if (!userId) {
      userId = crypto.randomUUID();
      localStorage.setItem("user_id", userId);
    }
    this.pushEvent("join", { user_id: userId });
    localStream = await navigator.mediaDevices.getUserMedia({
      video: true,
      audio: true,
    });
    remoteStream = new MediaStream();
    const webcamVideo = document.getElementById("webcamVideo");
    webcamVideo.srcObject = localStream;
    webcamVideo.muted = true;

    // Push tracks from local stream to peer connection
    localStream.getTracks().forEach((track) => {
      pc.addTrack(track, localStream);
    });

    pc.ontrack = (event) => {
      event.streams[0].getTracks().forEach((track) => {
        remoteStream.addTrack(track);
      });
    };

    const remoteVideo = document.getElementById("remoteVideo");
    remoteVideo.srcObject = remoteStream;
    // Get local candidate and let the server know
    pc.onicecandidate = (event) => {
      event.candidate &&
        this.pushEvent("candidate_info", event.candidate.toJSON());
    };
  },
};

export default Hooks;
