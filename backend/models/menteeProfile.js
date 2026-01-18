const mongoose = require('mongoose');

const MenteeProfileSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  firstName: { type: String, required: true },
  lastName: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  age: { type: Number, required: true },
  institution: { type: String, required: true },
  location: { type: String, required: true },
  // Remove the 'required' flag for classLevel (or remove it altogether if not needed)
  classLevel: { type: String }
});

module.exports = mongoose.model('MenteeProfile', MenteeProfileSchema);
