// controllers/rechargeController.js
const rechargeService = require('../services/recharge/rechargeService');
const logger = require('../utils/logger');
const crypto = require('crypto');
const db = require('../config/db');
const walletService = require('../services/walletService'); // Uncommented this
const partnerAuth = require('../services/partnerAuthService');
const axios = require('axios');
const { encrypt, decrypt } = require('../services/vimoEncryption'); // ← ADD THIS IMPORT!

const VIMO_BASE = 'https://gateway.vimopay.in';

class RechargeController {

    // ─────────────────────────────────────────────
    // GET OPERATOR LIST
    // POST /api/recharge/operators
    // ─────────────────────────────────────────────
    async getOperatorList(req, res) {
    try {
        const token = await partnerAuth.getBearerToken();
        const encryptedPayload = encrypt(JSON.stringify({ ServiceType: 'MBL' }));
        
        const response = await axios.post(
            `${VIMO_BASE}/masterapi/api/master/getoperator`,
            { requestBody: encryptedPayload },
            {
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'userId': process.env.PARTNER_USER_ID,
                    'Content-Type': 'application/json'
                }
            }
        );
        
        console.log('=== OPERATOR API RESPONSE ===');
        console.log('successStatus:', response.data.successStatus);
        console.log('data:', response.data.data);
        console.log('data length:', response.data.data?.length);
        
        // Check if we got real data (response data should be long encrypted string)
        let hasRealData = false;
        let operators = null;
        
        if (response.data.successStatus === true && response.data.data) {
            // If data is a long string (encrypted), try to decrypt
            if (typeof response.data.data === 'string' && response.data.data.length > 50) {
                try {
                    const decrypted = decrypt(response.data.data);
                    if (decrypted && decrypted.length > 10) {
                        operators = JSON.parse(decrypted);
                        if (operators && Array.isArray(operators) && operators.length > 0) {
                            hasRealData = true;
                        }
                    }
                } catch (e) {
                    console.log('Decryption failed:', e.message);
                }
            }
            // If data is already an object/array
            else if (typeof response.data.data === 'object' && response.data.data !== null) {
                operators = response.data.data;
                if (Array.isArray(operators) && operators.length > 0) {
                    hasRealData = true;
                }
            }
        }
        
        // Return real data if available
        if (hasRealData && operators) {
            return res.status(200).json({
                success: true,
                message: "Operators retrieved successfully",
                operators: operators
            });
        }
        
        // Otherwise return mock data
        console.log('No real data from VimoPay, returning mock operators');
        const mockOperators = [
            { "code": "AIR", "description": "Airtel", "circle": "ALL" },
            { "code": "VOD", "description": "Vodafone Idea", "circle": "ALL" },
            { "code": "JIO", "description": "Jio", "circle": "ALL" },
            { "code": "BSNL", "description": "BSNL", "circle": "ALL" },
            { "code": "MTNL", "description": "MTNL", "circle": "MUM" }
        ];
        
        return res.status(200).json({
            success: true,
            message: "Mock data (UAT environment - no real operators data)",
            operators: mockOperators
        });
        
    } catch (error) {
        console.error('getOperatorList error:', error.message);
        
        // Return mock data on error
        const mockOperators = [
            { "code": "AIR", "description": "Airtel", "circle": "ALL" },
            { "code": "VOD", "description": "Vodafone Idea", "circle": "ALL" },
            { "code": "JIO", "description": "Jio", "circle": "ALL" },
            { "code": "BSNL", "description": "BSNL", "circle": "ALL" }
        ];
        
        return res.status(200).json({
            success: true,
            message: "Mock data (API error)",
            operators: mockOperators
        });
    }
}

    // ─────────────────────────────────────────────
    // GET CIRCLE LIST
    // GET /api/recharge/circles
    // ─────────────────────────────────────────────
  async getCircleList(req, res) {
    try {
        // Always return mock data for now (UAT has no real data)
        console.log('Returning mock circle data');
        
        const mockCircles = [
            { "code": "AP", "description": "Andhra Pradesh" },
            { "code": "AS", "description": "Assam" },
            { "code": "BJH", "description": "Bihar Jharkhand" },
            { "code": "DLT", "description": "Delhi" },
            { "code": "GUJ", "description": "Gujarat" },
            { "code": "HRY", "description": "Haryana" },
            { "code": "HP", "description": "Himachal Pradesh" },
            { "code": "JNK", "description": "Jammu & Kashmir" },
            { "code": "KAR", "description": "Karnataka" },
            { "code": "KER", "description": "Kerala" },
            { "code": "MP", "description": "Madhya Pradesh" },
            { "code": "MAH", "description": "Maharashtra" },
            { "code": "NE", "description": "North East" },
            { "code": "ORI", "description": "Odisha" },
            { "code": "PUN", "description": "Punjab" },
            { "code": "RAJ", "description": "Rajasthan" },
            { "code": "TN", "description": "Tamil Nadu" },
            { "code": "UP_E", "description": "Uttar Pradesh East" },
            { "code": "UP_W", "description": "Uttar Pradesh West" },
            { "code": "WB", "description": "West Bengal" }
        ];
        
        return res.status(200).json({
            success: true,
            circles: mockCircles
        });
        
    } catch (error) {
        console.error('getCircleList error:', error.message);
        
        // Fallback mock circles
        const mockCircles = [
            { "code": "AP", "description": "Andhra Pradesh" },
            { "code": "DLT", "description": "Delhi" },
            { "code": "MAH", "description": "Maharashtra" },
            { "code": "TN", "description": "Tamil Nadu" }
        ];
        
        return res.status(200).json({
            success: true,
            circles: mockCircles
        });
    }
}
    // ─────────────────────────────────────────────
    // Mock plans data based on operator and circle
    // ─────────────────────────────────────────────
    getMockPlans(operatorCode, circleCode, mobileNumber) {
        const operatorPlans = {
            "AIR": [
                { amount: 199, validity: "28 days", data: "2GB/day", voice: "Unlimited", sms: "100/day", description: "Daily Data Pack" },
                { amount: 299, validity: "28 days", data: "3GB/day", voice: "Unlimited", sms: "100/day", description: "Daily Data Pack" },
                { amount: 399, validity: "56 days", data: "2GB/day", voice: "Unlimited", sms: "100/day", description: "Weekend Data Rollover" },
                { amount: 449, validity: "84 days", data: "1.5GB/day", voice: "Unlimited", sms: "100/day", description: "Long Validity Plan" },
                { amount: 599, validity: "56 days", data: "3GB/day", voice: "Unlimited", sms: "100/day", description: "Premium Plan" },
                { amount: 699, validity: "84 days", data: "2GB/day", voice: "Unlimited", sms: "100/day", description: "Entertainment Pack" },
                { amount: 999, validity: "84 days", data: "3GB/day", voice: "Unlimited", sms: "100/day", description: "Disney+ Hotstar" },
                { amount: 1499, validity: "365 days", data: "24GB total", voice: "Unlimited", sms: "100/day", description: "Yearly Plan" }
            ],
            "JIO": [
                { amount: 189, validity: "28 days", data: "2GB/day", voice: "Unlimited", sms: "100/day", description: "Daily Data Pack" },
                { amount: 249, validity: "28 days", data: "3GB/day", voice: "Unlimited", sms: "100/day", description: "Daily Data Pack" },
                { amount: 349, validity: "56 days", data: "2GB/day", voice: "Unlimited", sms: "100/day", description: "Long Validity" },
                { amount: 399, validity: "56 days", data: "3GB/day", voice: "Unlimited", sms: "100/day", description: "Jio Cinema Plan" },
                { amount: 449, validity: "84 days", data: "1.5GB/day", voice: "Unlimited", sms: "100/day", description: "Long Validity Plan" },
                { amount: 599, validity: "84 days", data: "2GB/day", voice: "Unlimited", sms: "100/day", description: "Premium Plan" },
                { amount: 899, validity: "84 days", data: "3GB/day", voice: "Unlimited", sms: "100/day", description: "Netflix Pack" },
                { amount: 1559, validity: "365 days", data: "24GB total", voice: "Unlimited", sms: "100/day", description: "Yearly Plan" }
            ],
            "VOD": [
                { amount: 199, validity: "28 days", data: "2GB/day", voice: "Unlimited", sms: "100/day", description: "Daily Data Pack" },
                { amount: 289, validity: "28 days", data: "3GB/day", voice: "Unlimited", sms: "100/day", description: "Daily Data Pack" },
                { amount: 349, validity: "56 days", data: "2GB/day", voice: "Unlimited", sms: "100/day", description: "Long Validity" },
                { amount: 429, validity: "84 days", data: "1.5GB/day", voice: "Unlimited", sms: "100/day", description: "Weekend Data Rollover" },
                { amount: 549, validity: "56 days", data: "3GB/day", voice: "Unlimited", sms: "100/day", description: "Premium Plan" },
                { amount: 749, validity: "84 days", data: "2GB/day", voice: "Unlimited", sms: "100/day", description: "Amazon Prime Pack" },
                { amount: 1199, validity: "84 days", data: "3GB/day", voice: "Unlimited", sms: "100/day", description: "Netflix Plan" },
                { amount: 1499, validity: "365 days", data: "24GB total", voice: "Unlimited", sms: "100/day", description: "Yearly Plan" }
            ],
            "BSNL": [
                { amount: 148, validity: "28 days", data: "2GB/day", voice: "Unlimited", sms: "100/day", description: "Daily Data Pack" },
                { amount: 239, validity: "28 days", data: "3GB/day", voice: "Unlimited", sms: "100/day", description: "Daily Data Pack" },
                { amount: 299, validity: "56 days", data: "2GB/day", voice: "Unlimited", sms: "100/day", description: "Long Validity" },
                { amount: 399, validity: "84 days", data: "1.5GB/day", voice: "Unlimited", sms: "100/day", description: "Long Validity Plan" },
                { amount: 499, validity: "84 days", data: "2GB/day", voice: "Unlimited", sms: "100/day", description: "Premium Plan" },
                { amount: 699, validity: "84 days", data: "3GB/day", voice: "Unlimited", sms: "100/day", description: "Entertainment Pack" },
                { amount: 1199, validity: "180 days", data: "10GB total", voice: "Unlimited", sms: "100/day", description: "Half Yearly Plan" },
                { amount: 1999, validity: "365 days", data: "20GB total", voice: "Unlimited", sms: "100/day", description: "Yearly Plan" }
            ],
            "MTNL": [
                { amount: 129, validity: "28 days", data: "1.5GB/day", voice: "Unlimited", sms: "100/day", description: "Daily Data Pack" },
                { amount: 199, validity: "28 days", data: "2GB/day", voice: "Unlimited", sms: "100/day", description: "Daily Data Pack" },
                { amount: 299, validity: "56 days", data: "2GB/day", voice: "Unlimited", sms: "100/day", description: "Long Validity" },
                { amount: 399, validity: "84 days", data: "1.5GB/day", voice: "Unlimited", sms: "100/day", description: "Long Validity Plan" },
                { amount: 499, validity: "84 days", data: "2GB/day", voice: "Unlimited", sms: "100/day", description: "Premium Plan" },
                { amount: 799, validity: "180 days", data: "15GB total", voice: "Unlimited", sms: "100/day", description: "Half Yearly Plan" },
                { amount: 1399, validity: "365 days", data: "30GB total", voice: "Unlimited", sms: "100/day", description: "Yearly Plan" }
            ]
        };
        
        let plans = operatorPlans[operatorCode] || operatorPlans["AIR"];
        
        // Add circle-specific plans
        if (circleCode === "DLT" || circleCode === "DEL") {
            plans.push({ amount: 49, validity: "1 day", data: "1GB", voice: "Unlimited", sms: "50", description: "1-Day Trial Pack (Delhi)" });
        }
        
        if (circleCode === "MAH" || circleCode === "MUM") {
            plans.push({ amount: 55, validity: "1 day", data: "1GB", voice: "Unlimited", sms: "50", description: "1-Day Trial Pack (Mumbai)" });
        }
        
        plans.sort((a, b) => a.amount - b.amount);
        
        return plans;
    }

    // ─────────────────────────────────────────────
    // FETCH MOBILE PLANS
    // POST /api/recharge/plans
    // ─────────────────────────────────────────────
   async getMobilePlans(req, res) {
    try {
        const { operatorCode, circleCode, mobileNumber } = req.body;
        
        if (!operatorCode || !circleCode || !mobileNumber) {
            return res.status(400).json({ 
                success: false, 
                message: 'operatorCode, circleCode and mobileNumber are required' 
            });
        }
        
        console.log('Getting plans for:', { operatorCode, circleCode, mobileNumber });
        
        // Always return mock data for now (UAT API is not working)
        const mockPlans = this.getMockPlans(operatorCode, circleCode, mobileNumber);
        
        return res.status(200).json({
            success: true,
            operator: operatorCode,
            circle: circleCode,
            mobile: mobileNumber,
            plans: mockPlans
        });
        
    } catch (error) {
        console.error('getMobilePlans error:', error.message);
        
        // Return basic mock plans on error
        const fallbackPlans = [
            { amount: 199, validity: "28 days", data: "2GB/day", voice: "Unlimited", sms: "100/day", description: "Basic Plan" },
            { amount: 399, validity: "56 days", data: "2GB/day", voice: "Unlimited", sms: "100/day", description: "Standard Plan" },
            { amount: 599, validity: "84 days", data: "3GB/day", voice: "Unlimited", sms: "100/day", description: "Premium Plan" }
        ];
        
        return res.status(200).json({
            success: true,
            message: "Mock data (API error)",
            plans: fallbackPlans
        });
    }
}

    // ─────────────────────────────────────────────
    // PROCESS RECHARGE
    // POST /api/recharge
    // ─────────────────────────────────────────────
  async processRecharge(req, res) {
    try {
        const userId = req.user.id;
        const { mobile, operator, circle, amount, idempotencyKey, testMode } = req.body;

        if (!mobile || !operator || !circle || !amount) {
            return res.status(400).json({
                success: false,
                error: 'Missing required fields: mobile, operator, circle, amount'
            });
        }

        if (!/^\d{10}$/.test(mobile)) {
            return res.status(400).json({
                success: false,
                error: 'Invalid mobile number. Must be 10 digits.'
            });
        }

        if (amount < 10 || amount > 10000) {
            return res.status(400).json({
                success: false,
                error: 'Amount must be between ₹10 and ₹10,000'
            });
        }

        logger.info(`RechargeController: Processing recharge for user ${userId}, mobile: ${mobile}, amount: ${amount}`);

        // For testing, always return success with mock transaction
        // This allows you to test the frontend flow
        if (testMode || process.env.NODE_ENV === 'development') {
            const mockTransactionId = `TXN${Date.now()}${Math.floor(Math.random() * 10000)}`;
            
            return res.status(200).json({
                success: true,
                message: "Test recharge successful (mock)",
                data: {
                    transactionId: mockTransactionId,
                    provider: "VIMO_PAY",
                    refunded: false,
                    amount: amount,
                    mobile: mobile,
                    operator: operator,
                    circle: circle
                }
            });
        }

        // Real recharge processing (when VimoPay is ready)
        const result = await rechargeService.processRecharge(
            userId,
            {
                mobile,
                operator,
                circle,
                amount: parseFloat(amount),
                testMode
            },
            idempotencyKey
        );

        return res.status(200).json({
            success: result.success,
            message: result.message,
            data: {
                transactionId: result.transactionId,
                provider: result.provider,
                refunded: result.refunded
            }
        });

    } catch (error) {
        logger.error('RechargeController: Error processing recharge', { error: error.message });
        
        // Return mock success for testing instead of error
        // This helps with frontend development
        if (process.env.NODE_ENV === 'development') {
            const mockTransactionId = `TXN${Date.now()}${Math.floor(Math.random() * 10000)}`;
            
            return res.status(200).json({
                success: true,
                message: "Mock recharge successful (development mode)",
                data: {
                    transactionId: mockTransactionId,
                    provider: "MOCK",
                    refunded: false,
                    amount: req.body.amount,
                    mobile: req.body.mobile,
                    operator: req.body.operator
                }
            });
        }
        
        if (error.message.includes('Insufficient balance')) {
            return res.status(400).json({
                success: false,
                error: error.message
            });
        }
        return res.status(500).json({
            success: false,
            error: 'Failed to process recharge. Please try again.'
        });
    }
}

    // ─────────────────────────────────────────────
    // GET USER RECHARGE HISTORY
    // GET /api/recharge/history
    // ─────────────────────────────────────────────
    async getUserHistory(req, res) {
        try {
            const userId = req.user.id;
            const limit = parseInt(req.query.limit) || 50;
            const offset = parseInt(req.query.offset) || 0;
            const history = await rechargeService.getUserHistory(userId, limit, offset);
            return res.status(200).json({ 
                success: true, 
                data: history, 
                pagination: { limit, offset, count: history.length } 
            });
        } catch (error) {
            logger.error('RechargeController: Error fetching user history', { error: error.message });
            return res.status(500).json({ success: false, error: 'Failed to fetch recharge history' });
        }
    }

    // ─────────────────────────────────────────────
    // GET ALL RECHARGES (ADMIN)
    // GET /api/recharge/admin/all
    // ─────────────────────────────────────────────
    async getAllRecharges(req, res) {
        try {
            const limit = parseInt(req.query.limit) || 50;
            const offset = parseInt(req.query.offset) || 0;
            const filters = { 
                status: req.query.status, 
                operator: req.query.operator, 
                search: req.query.search 
            };
            const result = await rechargeService.getAllRecharges(filters, limit, offset);
            return res.status(200).json({ 
                success: true, 
                data: result.transactions, 
                pagination: { 
                    limit: result.limit, 
                    offset: result.offset, 
                    total: result.total, 
                    count: result.transactions.length 
                } 
            });
        } catch (error) {
            logger.error('RechargeController: Error fetching all recharges', { error: error.message });
            return res.status(500).json({ success: false, error: 'Failed to fetch recharges' });
        }
    }

    // ─────────────────────────────────────────────
    // HANDLE PROVIDER CALLBACK (WEBHOOK)
    // POST /api/recharge/callback
    // ─────────────────────────────────────────────
    async handleCallback(req, res) {
        try {
            const { txn_id, status, amount, hash } = req.body;

            // 1. Verify signature
            const secret = process.env.CALLBACK_SECRET;
            if (!secret) {
                logger.error('CALLBACK_SECRET not set in environment');
                return res.status(500).json({ success: false, error: 'Server configuration error' });
            }
            
            const expectedHash = crypto.createHash('md5').update(txn_id + amount + secret).digest('hex');
            if (hash !== expectedHash) {
                logger.warn(`Invalid callback signature for txn ${txn_id}`);
                return res.status(401).json({ success: false, error: 'Invalid signature' });
            }

            // 2. Find transaction by provider_txn_id
            const transaction = await db.query(
                'SELECT id, user_id, plan_amount, status FROM transactions WHERE provider_txn_id = $1',
                [txn_id]
            );
            
            if (transaction.rows.length === 0) {
                return res.status(404).json({ success: false, error: 'Transaction not found' });
            }

            const txn = transaction.rows[0];
            if (txn.status !== 'pending') {
                return res.status(200).json({ success: true, message: 'Already processed' });
            }

            // 3. Update transaction status
            const newStatus = status === 'success' ? 'success' : 'failed';
            await db.query(
                'UPDATE transactions SET status = $1, updated_at = NOW() WHERE id = $2',
                [newStatus, txn.id]
            );

            // 4. If failed, refund wallet
            if (newStatus === 'failed') {
                await walletService.addMoney(
                    txn.user_id,
                    txn.plan_amount,
                    `Refund from callback for transaction ${txn.id}`,
                    null
                );
                logger.info(`Refunded ₹${txn.plan_amount} for failed callback transaction ${txn.id}`);
            }

            return res.status(200).json({ success: true, message: 'Callback processed' });
            
        } catch (error) {
            logger.error('Callback error:', error);
            return res.status(500).json({ success: false, error: 'Internal error' });
        }
    }
}

// Export as a single instance
module.exports = new RechargeController();