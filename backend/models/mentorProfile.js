const mongoose = require('mongoose');
const Schema = mongoose.Schema;


// Define the socialLinks sub-schema
const SocialLinkSchema = new mongoose.Schema({
    platform: {
        type: String,
        required: true
    },
    link: {
        type: String,
        required: true
    }
}, { _id: false }); 


const mentorProfileSchema = new Schema({
    user: {
        type: Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },

    firstName: {
        type: String,
        required: true
    },
    lastName: {
        type: String,
        required: true
    },
    location: {
        type: String,
        required: true
    },
    qualifications: {
        type: String,
        required: true
    },
    skills: {
        type: [String],
        required: true
    },
    jobTitle: {
        type: String,
        required: true
    },
    category: {
        type: String,
        required: true
    },
    bio: {
        type: String,
        required: true 
    },
    classLevel: { 
        type: String, 
        required: true 
    },
    subjects: [{
        type: String,
        required: true
    }],
    fieldOfStudy: { type: String }, 
    socialLinks: [SocialLinkSchema], 
    profilePicture: {
        type: String,
        default: '/uploads/profilePictures/default.png'
    },
    certificates: [{ 
        type: String,
        default: [] 
    }],
    verified: { 
        type: Boolean, 
        default: false 
    },
    createdAt: {
        type: Date,
        default: Date.now
    },
    updatedAt: {
        type: Date,
        default: Date.now
        
    }
})

// Update the updatedAt field before saving
mentorProfileSchema.pre('save', function(next) {
    this.updatedAt = Date.now();
    next();
});

module.exports = mongoose.model('MentorProfile', mentorProfileSchema);