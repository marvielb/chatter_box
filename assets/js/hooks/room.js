let remoteStream = null;
let localStream = null;
const servers = {
  iceServers: [
    {
      urls: ["stun:stun1.l.google.com:19302", "stun:stun2.l.google.com:19302"],
    },
  ],
  iceCandidatePoolSize: 10,
};

/**
 * @type {import("phoenix_live_view").ViewHook}
 */
let Hooks = {};
Hooks.Webcam = {
  async mounted() {
    const pc = new RTCPeerConnection(servers);
    const cachedCandidates = [];
    this.handleEvent("create_offer", async () => {
      console.log("creating offer..");
      const offerDescription = await pc.createOffer();
      await pc.setLocalDescription(offerDescription);

      const offer = {
        sdp: offerDescription.sdp,
        type: offerDescription.type,
      };
      this.pushEvent("offer_info", offer);
    });
    this.handleEvent("set_offer", async (offer) => {
      console.log("setting_offer and creating answer...");
      await pc.setRemoteDescription(new RTCSessionDescription(offer));

      const answerDescription = await pc.createAnswer();
      await pc.setLocalDescription(answerDescription);

      const answer = {
        type: answerDescription.type,
        sdp: answerDescription.sdp,
      };
      this.pushEvent("answer_info", answer);
    });

    this.handleEvent("set_answer", async (answer) => {
      console.log("setting_answer..");
      const answerDescription = new RTCSessionDescription(answer);
      pc.setRemoteDescription(answerDescription);
      cachedCandidates.forEach((candidate) => {
        const rtccandidate = new RTCIceCandidate(candidate);
        pc.addIceCandidate(rtccandidate);
      });
    });

    this.handleEvent("set_candidate", async (candidate) => {
      console.log("setting_candidate..", candidate);
      if (pc.currentRemoteDescription) {
        const rtccandidate = new RTCIceCandidate(candidate);
        pc.addIceCandidate(rtccandidate);
      } else {
        cachedCandidates.push(candidate);
      }
    });
    try {
      localStream = await navigator.mediaDevices.getUserMedia({
        video: true,
        audio: true,
      });
    } catch (_) {
      this.pushEvent("no_camera");
    }

    if (localStream) {
      const webcamVideo = document.getElementById("webcamVideo");
      webcamVideo.srcObject = localStream;
      webcamVideo.muted = true;

      remoteStream = new MediaStream();
      const remoteVideo = document.getElementById("remoteVideo");
      remoteVideo.srcObject = remoteStream;

      // Push tracks from local stream to peer connection
      localStream.getTracks().forEach((track) => {
        pc.addTrack(track, localStream);
      });
    }

    // Get local candidate and let the server know
    pc.onicecandidate = (event) => {
      event.candidate &&
        this.pushEvent("candidate_info", event.candidate.toJSON());
    };

    pc.ontrack = (event) => {
      event.streams[0].getTracks().forEach((track) => {
        remoteStream.addTrack(track);
      });
    };

    let userId = localStorage.getItem("user_id");
    if (!userId) {
      userId = crypto.randomUUID();
      localStorage.setItem("user_id", userId);
    }
    this.pushEvent("join", { user_id: userId });
  },
};

export default Hooks;
