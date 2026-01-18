let io;
const clients = {}; // Store connected users

module.exports = {
  // Initializes the Socket.IO server.
  init: (httpServer) => {
    const { Server } = require('socket.io');
    io = new Server(httpServer, {
      cors: {
        origin: '', // Update this to restrict access to specific frontend URLs
      },
    });

    // Handling connection
    io.on('connection', (socket) => {
      console.log('New WebSocket connection established');

      // Listen for a join event to register the user.
      socket.on('join', (userId) => {
        clients[userId] = socket;
        console.log(`User ${userId} connected`);
      });

      // Remove the user from clients on disconnect.
      socket.on('disconnect', () => {
        for (const userId in clients) {
          if (clients[userId] === socket) {
            delete clients[userId];
            console.log(`User ${userId} disconnected`);
            break;
          }
        }
      });
    });

    return io;
  },

  // Returns the initialized Socket.IO instance.
  getIO: () => {
    if (!io) {
      throw new Error('Socket.io is not initialized!');
    }
    return io;
  },

  // Helper function to send a notification to a specific user.
  sendNotification: (userId, message) => {
    if (clients[userId]) {
      // Send notification directly to the connected client.
      clients[userId].emit('notification', { userId, message });
      console.log(`Notification sent to user ${userId}: ${message}`);
    } else {
      // Optionally, broadcast the notification if the user is not connected.
      io.emit('notification', { userId, message });
      console.log(`User ${userId} not connected. Broadcasted notification: ${message}`);
    }
  },
};