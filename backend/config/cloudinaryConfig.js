const cloudinary = require('cloudinary').v2;

cloudinary.config({
  cloud_name: "datejuss2",
  api_key: "963397699637661",
  api_secret: "f-7O1kw5onpZuxv_vRrPWGe1upU"
});

module.exports = cloudinary;
