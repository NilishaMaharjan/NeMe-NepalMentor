const multer = require('multer');
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const cloudinary = require('../config/cloudinaryConfig');

// Set up Cloudinary storage for images and files (PDFs)r
const storage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: (req, file) => {
    return {
      folder: 'nepal_mentors', // Cloudinary folder name
      allowed_formats: ['jpg', 'png', 'jpeg', 'pdf'], // Allowed file types
    };
  },
});

const upload = multer({ storage });

module.exports = upload;
