const express = require("express");
const mongoose = require("mongoose");
const router = express.Router();
const Message = require("../models/Message");

// Get Messages for a Specific Slot
router.get("/:slotId", async (req, res) => {
  try {
    // Convert slotId from string to ObjectId
    const slotObjectId = new mongoose.Types.ObjectId(req.params.slotId);

    // Fetch messages for the specific slotId
    // IMPORTANT: Populate the sender field
    const messages = await Message.find({ slotId: slotObjectId })
      .populate("sender", "firstName lastName role")
      .sort("createdAt");

    res.json(messages);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Error fetching chat messages" });
  }
});

// Send Message for a Specific Slot
router.post("/send", async (req, res) => {
  try {
    const { slotId, sender, receiver, message } = req.body;

    // Convert slotId from string to ObjectId
    const slotObjectId = new mongoose.Types.ObjectId(slotId);

    const newMessage = new Message({
      slotId: slotObjectId,
      sender: new mongoose.Types.ObjectId(sender),
      receiver: receiver ? new mongoose.Types.ObjectId(receiver) : null,
      message
    });
    await newMessage.save();
    res.status(201).json({ message: "Message sent successfully", newMessage });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Error sending message" });
  }
});

module.exports = router;