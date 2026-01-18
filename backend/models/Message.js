const mongoose = require("mongoose");

const MessageSchema = new mongoose.Schema({
    slotId: { 
        type: mongoose.Schema.Types.ObjectId,  //  ObjectId
        required: true,
        ref: "Availability" 
    },
    sender: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    receiver: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: false },
    message: { type: String, required: true },
    createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model("Message", MessageSchema);