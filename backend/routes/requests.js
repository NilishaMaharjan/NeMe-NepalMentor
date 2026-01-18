const express = require('express');
const mongoose = require('mongoose');
const Request = require('../models/request'); // Request schema
const User = require('../models/users'); // User schema
const Notification = require('../models/notification');
const router = express.Router();

// POST /api/requests: Create a new request
router.post('/', async (req, res) => {
  const { mentor, userId, slotId,slot, message } = req.body;

  try {
    if (!mentor || !userId || !slotId) {
      return res.status(400).json({ error: 'Mentor ID, User ID, and Slot ID are required' });
    }

    const mentorId = new mongoose.Types.ObjectId(mentor);
    const menteeId = new mongoose.Types.ObjectId(userId);
    const slotObjectId = new mongoose.Types.ObjectId(slotId);

    const mentee = await User.findById(menteeId);
    if (!mentee) {
      return res.status(404).json({ error: 'Mentee not found' });
    }

    const mentorUser = await User.findById(mentorId);
    if (!mentorUser) {
      return res.status(404).json({ error: 'Mentor not found' });
    }

    const existingRequest = await Request.findOne({
      mentor: mentorId,
      mentee: menteeId,
      slotId: slotObjectId,
      status: { $in: ['pending', 'accepted'] },
    });

    if (existingRequest) {
      return res.status(400).json({ error: 'Request already exists for this mentor and slot' });
    }

    // Create new Request including extra fields: slot and message.

    const newRequest = new Request({
      mentee: menteeId,
      mentor: mentorId,
      slotId: slotObjectId,
      status: 'pending',
      slot,    // slot details (e.g., "Rs. 500/month - Home Tuition - 10:00 AM")
      message, // optional message
    });

    await newRequest.save();
    res.status(201).json(newRequest);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to send request' });
  }
});

// GET /api/requests/mentee: Fetch all requests sent by a mentee
router.get('/mentee', async (req, res) => {
  const { userId } = req.query;

  try {
    if (!userId) {
      return res.status(400).json({ error: 'User ID is required' });
    }

    const menteeId = new mongoose.Types.ObjectId(userId);
    const requests = await Request.find({ mentee: menteeId })
      .populate('mentor', 'firstName lastName email _id')
      .populate('mentee', 'firstName lastName email')
      .populate('slotId');  // Fetch slot details as stored

    const validRequests = requests.filter(req => req.mentor && req.mentee);

    if (validRequests.length === 0) {
      return res.status(404).json({ error: 'No requests found for this mentee' });
    }

    res.status(200).json(validRequests);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch requests' });
  }
});

// GET /api/requests/mentee/accepted: Fetch accepted requests for a mentee
router.get('/mentee/accepted', async (req, res) => {
  const { userId } = req.query;

  try {
    if (!userId) {
      return res.status(400).json({ error: 'User ID is required' });
    }

    const menteeId = new mongoose.Types.ObjectId(userId);
    const requests = await Request.find({ mentee: menteeId, status: 'accepted' })
      .populate('mentor', 'firstName lastName email _id')
      .populate('mentee', 'firstName lastName email')
      .populate('slotId', 'subject class time');

    const validRequests = requests.filter(req => req.mentor && req.mentee);

    if (validRequests.length === 0) {
      return res.status(404).json({ error: 'No accepted requests found for this mentee' });
    }

    // transform the response objects to include a custom structure.
    
    const transformed = validRequests.map(req => ({
      slotId: req.slotId._id,
      mentorName: `${req.mentor.firstName} ${req.mentor.lastName}`,
      subject: req.slotId.subject,
      class: req.slotId.class,
      time: req.slotId.time,
    }));

    // Send the transformed array.
    res.status(200).json(transformed);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch accepted requests' });
  }
});

// GET /api/requests/mentor: Fetch all pending requests received by a mentor
router.get('/mentor', async (req, res) => {
  const { userId } = req.query;

  try {
    if (!userId) {
      return res.status(400).json({ error: 'Mentor ID (userId) is required' });
    }

    const mentorId = new mongoose.Types.ObjectId(userId);
    const requests = await Request.find({ mentor: mentorId, status: 'pending' })
      .populate('mentee', 'firstName lastName email')
      .populate('mentor', 'firstName lastName email _id')
      .populate('slotId');

    const validRequests = requests.filter(req => req.mentor && req.mentee);

    if (validRequests.length === 0) {
      return res.status(404).json({ error: 'No requests found for this mentor' });
    }

    res.status(200).json(validRequests);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch requests for this mentor' });
  }
});

// GET /api/requests/mentor/accepted: Fetch all accepted requests received by a mentor
router.get('/mentor/accepted', async (req, res) => {
  const { userId } = req.query;

  try {
    if (!userId) {
      return res.status(400).json({ error: 'Mentor ID (userId) is required' });
    }

    const mentorId = new mongoose.Types.ObjectId(userId);
    const requests = await Request.find({ mentor: mentorId, status: 'accepted' })
      .populate('mentor', 'firstName lastName email')
      .populate('mentee', 'firstName lastName email')
      .populate('slotId');

    const validRequests = requests.filter(req => req.mentor && req.mentee);

    if (validRequests.length === 0) {
      return res.status(404).json({ error: 'No accepted requests found' });
    }

    res.status(200).json(validRequests);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch accepted requests' });
  }
});

// GET /api/requests/notifications/:userId - Fetch notifications for a specific user
router.get('/notifications/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const notifications = await Notification.find({ user: userId }).sort({ createdAt: -1 });

    if (!notifications.length) {
      return res.status(404).json({ message: 'No notifications found' });
    }

    res.json(notifications);
  } catch (error) {
    console.error('Error fetching notifications:', error);
    res.status(500).json({ error: 'Failed to fetch notifications' });
  }
});

// PATCH /api/requests/:id: Update the status of a request
router.patch('/:id', async (req, res) => {
  const { id } = req.params;
  const { status } = req.body;

  try {
    if (!status || !['accepted', 'rejected'].includes(status)) {
      return res.status(400).json({ error: 'Status must be either "accepted" or "rejected"' });
    }

    let requestDoc = await Request.findById(id).populate('mentor', 'firstName lastName');
    if (!requestDoc) {
      return res.status(404).json({ error: 'Request not found' });
    }

    if (requestDoc.status !== 'pending') {
      return res.status(400).json({ error: 'Request has already been processed (accepted or rejected)' });
    }

    requestDoc.status = status;
    requestDoc.updatedAt = Date.now();
    await requestDoc.save();

    if (status === 'accepted') {
      const mentorName = requestDoc.mentor
        ? `${requestDoc.mentor.firstName} ${requestDoc.mentor.lastName}`
        : 'Unknown';
      const notificationMessage = `Your request has been accepted by mentor ${mentorName}.`;

      const notification = new Notification({
        user: requestDoc.mentee._id,
        message: notificationMessage,
      });

      console.log('Attempting to save notification:', notification);
      try {
        await notification.save();
        console.log('Notification saved successfully:', notification);
      } catch (error) {
        console.error('Error saving notification:', error);
      }

      req.app.locals.getIO().emit('notification', {
        userId: requestDoc.mentee._id.toString(),
        message: notificationMessage,
      });
    }

    res.status(200).json(requestDoc);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to update request status' });
  }
});

// DELETE /api/requests/:id: Delete a request
router.delete('/:id', async (req, res) => {
  const { id } = req.params;

  try {
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ error: 'Invalid Request ID' });
    }

    const deletedRequest = await Request.findByIdAndDelete(id);
    if (!deletedRequest) {
      return res.status(404).json({ error: 'Request not found or invalid references' });
    }

    res.status(200).json({ message: 'Request deleted successfully' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to delete request' });
  }
});

module.exports = router;