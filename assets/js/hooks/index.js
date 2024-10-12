import QueueHooks from "./queue";
import RoomHooks from "./room";

let Hooks = { ...QueueHooks, ...RoomHooks };
export default Hooks;
