const express = require('express');
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const cors = require('cors');
const path = require('path');
const http = require('http');
const { Server } = require('socket.io');
const connectDB = require('./config/db');
const Message = require('./models/Message');
const Availability = require('./models/availability');
const Request = require("./models/request");

// Routes
const registerRoutes = require('./routes/register');
const mentorregisterRoutes = require('./routes/mentorregister');
const authRoutes = require('./routes/auth');
const mentorRoutes = require('./routes/mentor');
const mentorsRoutes = require('./routes/mentors');
const dashboardRoutes = require('./routes/dashboard');
const adminRoutes = require('./routes/admin');
const availabilityRoutes = require('./routes/availability');
const requestRoutes = require('./routes/requests');
const reviewRoutes = require('./routes/review');
const chatRoutes = require("./routes/chat");
const menteesRoutes = require('./routes/mentees');

dotenv.config();

const app = express();
const server = http.createServer(app);

// Initialize Socket.io
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

// Attach getIO function to app.locals so it can be used in routes
app.locals.getIO = () => io;

const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Connect to MongoDB
connectDB()
  .then(() => {
    console.log("MongoDB connected successfully.");
    server.listen(PORT, () => {
      console.log(`Server is running at http://localhost:${PORT}/`);
    });
  })
  .catch(err => {
    console.error('MongoDB connection error:', err);
  });

// Welcome route
app.get('/', (req, res) => {
  res.send('Welcome to the Nepal Mentor API');
});

// Routes
app.use('/api/register', registerRoutes);
app.use('/api/mentorregister', mentorregisterRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/mentor', mentorRoutes);
app.use('/api/mentors', mentorsRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/availability', availabilityRoutes);
app.use('/api/reviews', reviewRoutes);
app.use('/api/requests', requestRoutes);
app.use("/api/chat", chatRoutes);
app.use('/api/mentees', menteesRoutes);

// ----------------- Socket.io Chat Logic -----------------
io.on("connection", (socket) => {
  console.log("A user connected:", socket.id);

  // Debugging: Listen for any incoming event
  socket.onAny((event, data) => {
    console.log(`Received event: ${event}`, data);
  });

  // **Join Room**
  socket.on("joinRoom", async ({ slotId, userId }) => {
    console.log(`joinRoom event received: slotId=${slotId}, userId=${userId}`);

    // Validate slotId and userId formats
    if (!mongoose.Types.ObjectId.isValid(slotId) || !mongoose.Types.ObjectId.isValid(userId)) {
      console.log("Error: Invalid slotId or userId format");
      socket.emit("joinRoomError", "Invalid slotId or userId format");
      return;
    }

    try {
      const slotObjectId = new mongoose.Types.ObjectId(slotId);
      const userObjectId = new mongoose.Types.ObjectId(userId);

      // Check if the user is a mentor by finding an Availability document
      const availability = await Availability.findOne({ userId: userObjectId });
      if (availability) {
        // Mentor logic: Ensure the slot exists in the mentor's availability
        const slot = availability.slots.find(
          slot => slot._id.toString() === slotObjectId.toString()
        );
        if (!slot) {
          console.log("Error: Slot not found in the availability for mentor");
          socket.emit("joinRoomError", "Slot not found");
          return;
        }
      } else {
        // Mentee logic: fetch all accepted requests for this slot
        const acceptedRequests = await Request.find({
          slotId: slotObjectId,
          status: "accepted"
        });
        if (!acceptedRequests || acceptedRequests.length === 0) {
          console.log("No accepted requests found for slot");
          socket.emit("joinRoomError", "Your request is not accepted for this slot.");
          return;
        }
        // Check if any accepted request includes this mentee
        let isAccepted = false;
        acceptedRequests.forEach(req => {
          // Check if a single mentee field exists and matches
          if (req.mentee && req.mentee.toString() === userId) {
            isAccepted = true;
          }
          // Check if a mentees array exists and contains the userId
          if (req.mentees && Array.isArray(req.mentees)) {
            if (req.mentees.some(m => m._id.toString() === userId)) {
              isAccepted = true;
            }
          }
        });
        if (!isAccepted) {
          console.log("Request not accepted or does not exist for this slot for mentee");
          socket.emit("joinRoomError", "Your request is not accepted for this slot.");
          return;
        }
      }

      // Join the chat room
      socket.join(slotId);
      console.log(`User ${userId} successfully joined room ${slotId}`);

      // Fetch previous messages and send them to the client,
      // populating the sender so that user details (name, role, etc.) are included.
      const messages = await Message.find({ slotId: slotObjectId })
        .populate('sender', 'firstName lastName role')
        .sort({ createdAt: 1 });

      console.log(`Fetched ${messages.length} messages for slotId: ${slotId}`);
      console.log("Populated messages with sender details:", messages.map(msg => ({
        id: msg._id,
        message: msg.message,
        sender: msg.sender
      })));

      // Emit the populated messages to the client
      socket.emit("previousMessages", messages);
    } catch (error) {
      console.error("Error in joinRoom handler:", error);
      socket.emit("joinRoomError", "Error processing joinRoom");
    }
  });

  // **Send Message**
  socket.on("sendMessage", async ({ slotId, sender, receiver, message }) => {
    try {
      if (!slotId || !sender || !message) {
        console.log("Missing required fields for sending message");
        socket.emit("sendMessageError", "slotId, sender, and message are required.");
        return;
      }

      const newMessage = new Message({
        slotId,
        sender: new mongoose.Types.ObjectId(sender), // Ensure sender is stored as ObjectId
        receiver: receiver ? new mongoose.Types.ObjectId(receiver) : null,
        message,
      });

      await newMessage.save();
      console.log("New message saved, now populating sender details...");

      // Populate sender details from the User model (firstName, lastName, role)
      const populatedMessage = await newMessage.populate('sender', 'firstName lastName role');
      console.log("Populated new message:", {
        id: populatedMessage._id,
        message: populatedMessage.message,
        sender: populatedMessage.sender
      });

      // Broadcast the populated message to all users in the room
      io.to(slotId).emit("receiveMessage", populatedMessage);
      console.log(`Broadcasted message to room ${slotId}`);
    } catch (err) {
      console.error("Error sending message:", err);
      socket.emit("sendMessageError", "Error sending message.");
    }
  });

  socket.on("disconnect", () => {
    console.log("A user disconnected:", socket.id);
  });
});

// Catch-all route for 404
app.use((req, res) => {
  res.status(404).send('Not Found');
});

module.exports = app;
