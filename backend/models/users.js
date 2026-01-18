const mongoose = require('mongoose');
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


const UserSchema = new mongoose.Schema({
    firstName: {
        type: String,
        required: true
    },
    lastName: {
        type: String,
        required: true
    },
    email: {
        type: String,
        required: true,
        unique: true
    },
    password: {
        type: String,
        required: true
    },
    role: {
        type: String,
        enum: ['mentor', 'mentee'],
        required: true
    },
    location: {
        type: String,
        default: null
    },
    qualifications: {
        type: String,
        default: null
    },
    skills: {
        type: String,
        default: null
    },
    jobTitle: {
        type: String,
        default: null
    },
    category: {
        type: String,
        default: null
    },
    bio: {
        type: String,
        default: null
    },
    age: {
        type: Number,
        default: null
    },
    institution: {
        type: String,
        default: null
    },
    classLevel: { 
        type: String,
        required: function() {
            return this.role === 'mentor';
        }
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
    date: {
        type: Date,
        default: Date.now
    }
});

// Pre-save middleware to set fullName
UserSchema.pre('save', function(next) {
    this.fullName = `${this.firstName} ${this.lastName}`;
    next();
});

module.exports = mongoose.model('User', UserSchema);