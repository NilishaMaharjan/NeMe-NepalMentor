const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const AvailabilitySchema = new Schema({
    userId: {
        type: Schema.Types.ObjectId,
        ref: 'User', 
        required: true
    },
    slots: [{
        _id: { type: Schema.Types.ObjectId, default: () => new mongoose.Types.ObjectId() }, // Unique ID for each slot
        time: { type: String, required: true } ,
        price: { 
            type: Number, 
            required: true 
        },
        type: {
            type: String,
            enum: ['Online', 'Home Tuition'],
            required: true,
            default: 'Online'
        }


    }]
}, { timestamps: true });

module.exports = mongoose.model('Availability', AvailabilitySchema);