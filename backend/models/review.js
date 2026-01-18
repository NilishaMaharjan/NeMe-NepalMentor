const mongoose = require('mongoose');

const reviewSchema = new mongoose.Schema({
  mentorId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  review: { type: String, maxlength: 500, trim: true },
  rating: { type: Number, min: 0, max: 5, required: true },
  createdAt: { type: Date, default: Date.now },
});

// Export the review model
module.exports = mongoose.model('Review', reviewSchema);
