const jwt = require('jsonwebtoken');

// Middleware for logging requests and verifying JWT
module.exports = function (req, res, next) {
  // Log incoming requests
  console.log(`${req.method} request for '${req.url}'`);

  // Get token from the header
  const token = req.header('x-auth-token');

  // Check if token exists
  if (!token) {
    return res.status(401).json({ msg: 'No token, authorization denied' });
  }

  // Verify the token
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded.user; // Ensure 'user' matches your token payload
    next();
  } catch (err) {
    return res.status(401).json({ msg: 'Invalid token' });
  }
};
