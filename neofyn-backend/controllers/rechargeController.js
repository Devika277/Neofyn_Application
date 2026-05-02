// controllers/rechargeController.js
const rechargeService = require('../services/recharge/rechargeService');
const logger = require('../utils/logger');
const crypto = require('crypto');
const db = require('../config/db');
const partnerAuth = require('../services/partnerAuthService');
const { encrypt, decrypt } = require('../services/vimoEncryption');
const axios = require('axios');

const VIMO_BASE = 'http://gateway.vimopay.in';

// ─── Helper: Encrypted POST to VimoPay using GCM ─────────────────────────────
// In rechargeController.js - Update vimoPost function
async function vimoPost(url, payload) {
    try {
        const token = await partnerAuth.getBearerToken();
        
        // Encrypt the request
        const plainText = JSON.stringify(payload);
        const encryptedBody = encrypt(plainText);
        
        if (!encryptedBody) {
            throw new Error('Encryption failed');
        }
        
        console.log(`[vimoPost] Calling: ${url}`);
        
        const response = await axios.post(
            url,
            { requestBody: encryptedBody },
            {
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'userId': process.env.PARTNER_USER_ID,
                    'Content-Type': 'application/json'
                }
            }
        );
        
        console.log('[vimoPost] Response successStatus:', response.data.successStatus);
        console.log('[vimoPost] Response data length:', response.data.data?.length || 0);
        
        // Check if we have data to decrypt
        if (response.data.data && typeof response.data.data === 'string') {
            // If data is short (like 24 chars), it might be a test response or empty
            if (response.data.data.length < 50) {
                console.log('[vimoPost] Data too short to be encrypted, using as-is');
                // Try to base64 decode it
                try {
                    const decoded = Buffer.from(response.data.data, 'base64').toString('utf8');
                    if (decoded) {
                        response.data.data = decoded;
                    }
                } catch (e) {
                    // Keep original
                }
            } else {
                // Try to decrypt
                try {
                    const decryptedString = decrypt(response.data.data);
                    if (decryptedString) {
                        response.data.data = JSON.parse(decryptedString);
                        console.log('[vimoPost] Successfully decrypted response');
                    }
                } catch (decryptError) {
                    console.log('[vimoPost] Decryption failed, using raw data');
                }
            }
        }
        
        return response.data;
        
    } catch (error) {
        console.error('[vimoPost] Error:', error.response?.data || error.message);
        throw error;
    }
}

// ─── Helper: Encrypted GET to VimoPay ────────────────────────────────────────
async function vimoGet(url) {
    try {
        const token = await partnerAuth.getBearerToken();
        
        console.log(`[vimoGet] Calling: ${url}`);
        
        const response = await axios.get(url, {
            headers: {
                'Authorization': `Bearer ${token}`,
                'userId': process.env.PARTNER_USER_ID,
                'Content-Type': 'application/json'
            }
        });
        
        // Decrypt the response data if present
        if (response.data.data && typeof response.data.data === 'string') {
            try {
                const decryptedString = decrypt(response.data.data);
                if (decryptedString) {
                    response.data.data = JSON.parse(decryptedString);
                    console.log('[vimoGet] Successfully decrypted response');
                }
            } catch (decryptError) {
                console.error('[vimoGet] Failed to decrypt response:', decryptError.message);
            }
        }
        
        return response.data;
        
    } catch (error) {
        console.error('[vimoGet] Error:', error.response?.data || error.message);
        throw error;
    }
}

// ─── Controller Methods ──────────────────────────────────────────────────────

// POST /api/recharge/operators
// In rechargeController.js - Temporary mock for testing
exports.getOperatorList = async (req, res) => {
    try {
        // Try real API first
        const data = await vimoPost(`${VIMO_BASE}/masterapi/api/master/getoperator`, { 
            ServiceType: 'MBL' 
        });
        
        // If real data has no operators, return mock for testing
        if (!data.data || (typeof data.data === 'string' && data.data.length < 50)) {
            console.log('No real data from VimoPay, returning mock operators for testing');
            
            // Mock operator data for testing
            const mockOperators = [
                { operatorCode: "AIR", operatorName: "Airtel", circle: "ALL" },
                { operatorCode: "VOD", operatorName: "Vodafone Idea", circle: "ALL" },
                { operatorCode: "JIO", operatorName: "Jio", circle: "ALL" },
                { operatorCode: "BSNL", operatorName: "BSNL", circle: "ALL" }
            ];
            
            return res.status(200).json({ 
                success: true, 
                message: "Mock data - VimoPay UAT returning test response",
                operators: mockOperators
            });
        }
        
        return res.status(200).json({ 
            success: true, 
            message: data.message,
            operators: data.data 
        });
        
    } catch (error) {
        console.error('getOperatorList error:', error.message);
        
        // Return mock data on error for testing
        const mockOperators = [
            { operatorCode: "AIR", operatorName: "Airtel", circle: "ALL" },
            { operatorCode: "VOD", operatorName: "Vodafone Idea", circle: "ALL" },
            { operatorCode: "JIO", operatorName: "Jio", circle: "ALL" },
            { operatorCode: "BSNL", operatorName: "BSNL", circle: "ALL" }
        ];
        
        return res.status(200).json({ 
            success: true, 
            message: "Mock data - API error, using fallback",
            operators: mockOperators
        });
    }
};

// GET /api/recharge/circles
exports.getCircleList = async (req, res) => {
    try {
        const data = await vimoGet(`${VIMO_BASE}/masterapi/api/master/getcircle`);
        return res.status(200).json({ 
            success: true, 
            circles: data.data 
        });
    } catch (error) {
        console.error('getCircleList error:', error.message);
        return res.status(500).json({ 
            success: false, 
            message: error.message 
        });
    }
};

// POST /api/recharge/plans
exports.getMobilePlans = async (req, res) => {
    try {
        const { operatorCode, circleCode, mobileNumber } = req.body;
        
        if (!operatorCode || !circleCode || !mobileNumber) {
            return res.status(400).json({ 
                success: false, 
                message: 'operatorCode, circleCode and mobileNumber are required' 
            });
        }
        
        const merchantrefId = `REF${Date.now()}${Math.floor(Math.random() * 1000)}`;
        const data = await vimoPost(`${VIMO_BASE}/rechargeplanapi/api/payment/fetchplanuat`, {
            merchantrefId,
            mobileNumber,
            operatorCode,
            circleCode
        });
        
        return res.status(200).json({ 
            success: true, 
            plans: data.data 
        });
    } catch (error) {
        console.error('getMobilePlans error:', error.message);
        return res.status(500).json({ 
            success: false, 
            message: error.message 
        });
    }
};

// POST /api/recharge
exports.processRecharge = async (req, res) => {
    try {
        const userId = req.user.id;
        const { mobile, operator, circle, amount, idempotencyKey, testMode } = req.body;
        
        if (!mobile || !operator || !circle || !amount) {
            return res.status(400).json({ success: false, error: 'Missing required fields' });
        }
        
        if (!/^\d{10}$/.test(mobile)) {
            return res.status(400).json({ success: false, error: 'Invalid mobile number' });
        }
        
        if (amount < 10 || amount > 10000) {
            return res.status(400).json({ success: false, error: 'Amount must be ₹10–₹10,000' });
        }

        const result = await rechargeService.processRecharge(
            userId, { mobile, operator, circle, amount: parseFloat(amount), testMode }, idempotencyKey
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
        if (error.message.includes('Insufficient balance')) {
            return res.status(400).json({ success: false, error: error.message });
        }
        console.error('processRecharge error:', error);
        return res.status(500).json({ success: false, error: 'Failed to process recharge.' });
    }
};

// GET /api/recharge/history
exports.getUserHistory = async (req, res) => {
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
        console.error('getUserHistory error:', error);
        return res.status(500).json({ success: false, error: 'Failed to fetch history' });
    }
};

// POST /api/recharge/callback
exports.handleCallback = async (req, res) => {
    try {
        const { txn_id, status, amount, hash } = req.body;
        const secret = process.env.CALLBACK_SECRET;
        
        if (!secret) {
            return res.status(500).json({ success: false, error: 'Server config error' });
        }

        const expectedHash = crypto.createHash('md5').update(txn_id + amount + secret).digest('hex');
        
        if (hash !== expectedHash) {
            return res.status(401).json({ success: false, error: 'Invalid signature' });
        }

        const transaction = await db.query(
            'SELECT id, user_id, plan_amount, status FROM transactions WHERE provider_txn_id = $1', 
            [txn_id]
        );
        
        if (transaction.rows.length === 0) {
            return res.status(404).json({ success: false, error: 'Not found' });
        }

        const txn = transaction.rows[0];
        
        if (txn.status !== 'pending') {
            return res.status(200).json({ success: true, message: 'Already processed' });
        }

        const newStatus = status === 'success' ? 'success' : 'failed';
        await db.query(
            'UPDATE transactions SET status = $1, updated_at = NOW() WHERE id = $2', 
            [newStatus, txn.id]
        );

        return res.status(200).json({ success: true, message: 'Callback processed' });
    } catch (error) {
        console.error('handleCallback error:', error);
        return res.status(500).json({ success: false, error: 'Internal error' });
    }
};