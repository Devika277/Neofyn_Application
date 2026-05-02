const express = require('express');
const router = express.Router();
const rechargeController = require('../controllers/rechargeController');
const protect = require('../middleware/authMiddleware');
//const adminMiddleware = require('../middleware/adminMiddleware');

/**
 * Recharge Routes
 * Base path: /api/recharge
 */

console.log('✅ Methods loaded:', Object.keys(rechargeController));

// ✅ ADD THIS DEBUG
console.log('=== CONTROLLER DEBUG ===');
console.log('Controller methods:', Object.keys(rechargeController));
console.log('getOperatorList exists?', typeof rechargeController.getOperatorList);
console.log('processRecharge exists?', typeof rechargeController.processRecharge);
console.log('getUserHistory exists?', typeof rechargeController.getUserHistory);
console.log('handleCallback exists?', typeof rechargeController.handleCallback);
console.log('========================');

/**
 * POST /api/recharge/callback
 * Webhook callback from provider (public endpoint, no auth)
 * MUST be before the auth middleware
 */
router.post('/callback', rechargeController.handleCallback);

// All other recharge routes require authentication
//router.use(protect);

// Ensure this line exists!
router.post('/operators', protect, rechargeController.getOperatorList);

// GET circle list    →  GET /api/recharge/circles
router.get('/circles', protect, rechargeController.getCircleList);

// FETCH mobile plans →  POST /api/recharge/plans
// Body: { operatorCode, circleCode, mobileNumber }
router.post('/plans', protect, rechargeController.getMobilePlans);


/**
 * POST /api/recharge
 * Process a mobile recharge
 * Body: { mobile, operator, circle, amount, idempotencyKey, testMode }
 */
router.post('/', protect, rechargeController.processRecharge);

/**
 * GET /api/recharge/history
 * Get user's recharge history
 * Query: ?limit=50&offset=0
 */
router.get('/history', protect, rechargeController.getUserHistory);



/**
 * GET /api/recharge/admin/all
 * Admin: Get all recharges with filters
 * Query: ?status=&operator=&search=&limit=&offset=
 */
//router.get('/admin/all', protect, adminMiddleware, rechargeController.getAllRecharges);

module.exports = router;