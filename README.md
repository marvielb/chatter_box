# Chatterbox

Chatterbox is an omegle clone. That's it. The project's main goal is to learn about GenServers; to learn
how they work and how they communicate to one another.

## Demo

A live demo can be viewed here: https://chatterbox.marvielb.com/

## Features:

- Dead simple queing / matching system. You will get matched depending on the order of joining the queue.
- Video call is achieved by using [Web RTC](https://webrtc.org/). Signaling handled by GenServers and live view.
- Chat functionality using GenServer and LiveView.

## Technologies used:

- Elixir
- Phoenix Framework
- Live View
- Tailwind CSS
- GenServers
- WebRTC

## Screenshots

### Chat Room - Desktop

![swappy-20241022_212341](https://github.com/user-attachments/assets/7542c2ef-9d24-42c7-a783-986069500d1e)

### Chat Room - Mobile

![swappy-20241022_211345](https://github.com/user-attachments/assets/eed0a86e-6362-4a09-92c0-2ec7f1f95685)

### Queue - Desktop

![Screenshot 2024-10-22 at 21-03-10 Chatterbox · Phoenix Framework](https://github.com/user-attachments/assets/42385ee7-eec8-43c7-aae8-a5856bee3600)

### Queue - Mobile

![Screenshot 2024-10-22 at 21-03-27 Chatterbox · Phoenix Framework](https://github.com/user-attachments/assets/00508256-a35d-4ea9-9d19-05eae3ac71c1)

## Deployment

For the deployment, it uses [burrito](https://github.com/burrito-elixir/burrito) to assemble a single binary to be distributed to a linux server.
This is done to circumvent Elixir's hard deployment. Now, we just need to be running any linux on the server.

To deploy this:

- Make sure to setup the server to run the built binary on startup.
- Read the `deploy.sh` script in the root folder to get a clue on what it does
- Configure the `aws.box` host in the `/etc/hosts` file
- Run the script `deploy.sh`

## TODO

- [ ] Add telemetry.
- [ ] Refactor the room's HTML into modular components.
- [ ] More tests for the queue and the LiveView views.
