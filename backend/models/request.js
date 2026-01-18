const mongoose = require('mongoose');

const RequestSchema = new mongoose.Schema({
  mentee: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true }, // Mentee's userId
  mentor: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true }, // Mentor's userId
  slotId: { 
    type: mongoose.Schema.Types.ObjectId, 
    required: true 
  }, // Slot ID (from Availability.slots)
  slot: { type: String },      // Slot details (price, type, time) from frontend
  message: { type: String },   // Optional message from the request
  status: { type: String, enum: ['pending', 'accepted', 'rejected'], default: 'pending' },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now },
});

const Request = mongoose.model('Request', RequestSchema);

module.exports = Request;