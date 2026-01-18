const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const Availability = require('../models/availability'); 
const MentorProfile = require('../models/mentorProfile'); 
const User = require('../models/users'); 

// Validate that the time string is in the format "9:00 PM - 10:00 PM"
const isValidTimeSlot = (time) => {
  const timeRangeRegex = /^(0?[1-9]|1[0-2]):[0-5][0-9] ([APap][Mm])\s*-\s*(0?[1-9]|1[0-2]):[0-5][0-9] ([APap][Mm])$/;
  return timeRangeRegex.test(time);
};

// POST route to add slots to mentor availability
router.post('/:userId', async (req, res) => {
  const { userId } = req.params;
  let { slots } = req.body;

  if (!slots || !Array.isArray(slots) || slots.length === 0) {
    return res.status(400).json({ msg: 'Please provide an array of time slots.' });
  }

  for (let slot of slots) {
    if (typeof slot !== 'object' || !slot.time || slot.price === undefined) {
      return res.status(400).json({ msg: 'Each slot must have a time and a price.' });
    }
    slot.time = slot.time.trim();
    if (!isValidTimeSlot(slot.time)) {
      return res.status(400).json({ msg: `Invalid time slot format: ${slot.time}. Use "9:00 PM - 10:00 PM".` });
    }
    slot.price = parseInt(slot.price);
    if (isNaN(slot.price)) {
      return res.status(400).json({ msg: 'Price must be an integer.' });
    }
    // If type is not provided, default to "Online"
    if (!slot.type) {
      slot.type = "Online";
    }
  }

  try {
    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ msg: 'Invalid userId' });
    }

    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ msg: 'User not found' });

    const mentorProfile = await MentorProfile.findOne({
      $or: [{ _id: userId }, { user: userId }],
    });
    if (!mentorProfile) return res.status(404).json({ msg: 'Mentor profile not found' });

    const mentorId = mentorProfile.user;
    let availability = await Availability.findOne({ userId: mentorId });

    const newSlots = slots.map(slot => ({
      _id: new mongoose.Types.ObjectId(),
      time: slot.time,
      price: slot.price,
      type: slot.type
    }));

    if (availability) {
      const existingTimes = availability.slots.map(slot => slot.time);
      for (let slot of newSlots) {
        if (existingTimes.includes(slot.time)) {
          return res.status(400).json({ msg: `Slot '${slot.time}' is already taken.` });
        }
      }
      availability.slots.push(...newSlots);
      await availability.save();
      return res.status(200).json({ msg: 'Availability updated', availability });
    }

    availability = new Availability({ userId: mentorId, slots: newSlots });
    await availability.save();
    return res.status(201).json({ msg: 'Availability created', availability });
  } catch (err) {
    console.error(err.message);
    return res.status(500).send('Server error');
  }
});

// PUT route to update a specific slot by ID
router.put('/:userId/edit-slot/:slotId', async (req, res) => {
  const { userId, slotId } = req.params;
  const { newTime, newPrice, newType } = req.body;

  if (!isValidTimeSlot(newTime)) {
    return res.status(400).json({ msg: 'Provide a valid time slot in the correct format.' });
  }
  const parsedPrice = parseInt(newPrice);
  if (isNaN(parsedPrice)) {
    return res.status(400).json({ msg: 'Price must be an integer.' });
  }

  try {
    const availability = await Availability.findOne({ userId: new mongoose.Types.ObjectId(userId) });
    if (!availability) return res.status(404).json({ msg: 'Availability not found' });

    const slot = availability.slots.id(slotId);
    if (!slot) return res.status(404).json({ msg: 'Slot not found' });

    slot.time = newTime;
    slot.price = parsedPrice;
    // Update the new type attribute.
    slot.type = newType ? newType : "Online";
    await availability.save();
    return res.status(200).json({ msg: 'Slot updated', availability });
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});

// GET route to retrieve mentor availability
router.get('/:userId', async (req, res) => {
  const { userId } = req.params;
  try {
    const availability = await Availability.findOne({ userId: new mongoose.Types.ObjectId(userId) });
    if (!availability) return res.status(404).json({ msg: 'Availability not found' });
    res.json(availability);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});

// DELETE route to remove a specific slot by ID
router.delete('/:userId/delete-slot/:slotId', async (req, res) => {
  const { userId, slotId } = req.params;
  try {
    const availability = await Availability.findOne({ userId: new mongoose.Types.ObjectId(userId) });
    if (!availability) return res.status(404).json({ msg: 'Availability not found' });

    const slotIndex = availability.slots.findIndex(slot => slot._id.toString() === slotId);
    if (slotIndex === -1) return res.status(404).json({ msg: 'Slot not found' });

    availability.slots.splice(slotIndex, 1);
    await availability.save();
    return res.status(200).json({ msg: 'Slot deleted', availability });
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});


// GET route to retrieve slot details along with the mentor's user id using slot id
router.get('/slot/:slotId', async (req, res) => {
  const { slotId } = req.params;
  if (!mongoose.Types.ObjectId.isValid(slotId)) {
    return res.status(400).json({ msg: 'Invalid slot ID format' });
  }
  try {
    // Find the availability document that contains the slot
    const availability = await Availability.findOne({ 'slots._id': new mongoose.Types.ObjectId(slotId) });
    if (!availability) return res.status(404).json({ msg: 'Availability not found' });
    
    // Find the specific slot inside the slots array
    const slot = availability.slots.find(s => s._id.toString() === slotId);
    if (!slot) return res.status(404).json({ msg: 'Slot not found' });
    
    // Return the slot details along with the mentor's user id
    return res.status(200).json({ slot: slot, mentorUserId: availability.userId });
  } catch (err) {
    console.error(err.message);
    return res.status(500).send('Server error');
  }
});


module.exports = router;