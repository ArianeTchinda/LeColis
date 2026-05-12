const { io } = require("socket.io-client");

// On se connecte au serveur
const socket = io("http://localhost:5000");

socket.on("connect", () => {
  console.log("🛡️ Connecté au serveur en tant qu'Admin (ID: " + socket.id + ")");
  
  // On rejoint la room des admins
  socket.emit("join_admin_room");
});

// On écoute les nouveaux signalements
socket.on("new_signalement", (data) => {
  console.log("🚨 ALERTE : Nouveau signalement reçu !");
  console.log(data);
});

socket.on("report_claimed", (data) => {
  console.log("✅ Un admin a pris en charge un signalement !");
  console.log(data);
});