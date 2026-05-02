// routes/dmtRoute.js
const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');

// Database connection
const db = require('../config/db');

// ============ SENDER (REMITTER) REGISTRATION ============
router.post('/sender/register', async (req, res) => {
    const retailerId = req.user?.id || 1;
    
    try {
        const { senderMobile, senderName, senderState, senderCity,
                aadhaar, address, pinCode, ip, lat, long } = req.body;

        console.log('Registration request:', req.body);

        // Check if remitter already exists
        const existing = await db.query(
            `SELECT id FROM dmt_remitters
             WHERE retailer_id = $1 AND mobile = $2`,
            [retailerId, senderMobile]
        );

        const gatewayRefId = uuidv4();
        const nameParts = senderName.trim().split(' ');
        const firstName = nameParts[0];
        const lastName = nameParts.slice(1).join(' ') || '';

        if (existing.rows.length === 0) {
            // Insert new remitter - Only with columns that exist
            await db.query(
                `INSERT INTO dmt_remitters
                    (retailer_id, mobile, first_name, last_name, address, pincode,
                     aadhar_no, gateway_ref_id, sender_registered)
                 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, false)`,
                [retailerId, senderMobile, firstName, lastName,
                 address, pinCode, aadhaar, gatewayRefId]
            );
        }

        // Generate OTP for testing
        const otp = Math.floor(100000 + Math.random() * 900000);
        console.log(`OTP for ${senderMobile}: ${otp}`);

        res.json({
            success: true,
            message: "OTP sent successfully. Please verify OTP to complete registration.",
            senderMobile: senderMobile,
            otp: otp // Remove in production
        });
        
    } catch (e) {
        console.error('Sender registration error:', e);
        res.status(500).json({ success: false, message: e.message });
    }
});

// Retrigger sender OTP
router.post('/sender/retrigger-otp', async (req, res) => {
    try {
        const { senderMobile, senderName } = req.body;
        
        const otp = Math.floor(100000 + Math.random() * 900000);
        console.log(`OTP for ${senderMobile}: ${otp}`);
        
        res.json({
            success: true,
            message: "OTP sent successfully",
            otp: otp
        });
    } catch (e) {
        res.status(500).json({ success: false, message: e.message });
    }
});

// Verify sender OTP
router.post('/sender/verify-otp', async (req, res) => {
    const retailerId = req.user?.id || 1;
    
    try {
        const { senderMobile, otpPin } = req.body;
        
        // Accept any 6-digit OTP for testing
        if (otpPin && otpPin.length === 6) {
            const result = await db.query(
                `UPDATE dmt_remitters
                 SET sender_registered = true, updated_at = now()
                 WHERE retailer_id = $1 AND mobile = $2
                 RETURNING id`,
                [retailerId, senderMobile]
            );
            
            if (result.rows.length === 0) {
                return res.status(404).json({
                    success: false,
                    message: "Sender not found"
                });
            }
            
            res.json({
                success: true,
                message: "Sender verified successfully"
            });
        } else {
            res.status(400).json({
                success: false,
                message: "Invalid OTP. Please enter 6-digit OTP."
            });
        }
    } catch (e) {
        console.error('OTP verification error:', e);
        res.status(500).json({ success: false, message: e.message });
    }
});

// ============ BENEFICIARY ============

// Register beneficiary
router.post('/beneficiary/register', async (req, res) => {
    const retailerId = req.user?.id || 1;
    
    try {
        const { senderMobile, beneName, accountNo, ifsc, bankName } = req.body;

        // Get remitter
        const remRes = await db.query(
            `SELECT id FROM dmt_remitters
             WHERE retailer_id = $1 AND mobile = $2 AND sender_registered = true`,
            [retailerId, senderMobile]
        );
        
        if (!remRes.rows.length) {
            return res.status(400).json({
                success: false,
                message: 'Sender not found or not verified'
            });
        }
        
        const { id: remitterId } = remRes.rows[0];
        const beneCode = `BENE${Date.now()}${Math.floor(Math.random() * 1000)}`;

        // Save to dmt_beneficiaries
        const insertRes = await db.query(
            `INSERT INTO dmt_beneficiaries
                (remitter_id, account_holder_name, account_number, ifsc_code,
                 bank_name, bene_code, verified)
             VALUES ($1, $2, $3, $4, $5, $6, false)
             RETURNING id`,
            [remitterId, beneName, accountNo, ifsc, bankName, beneCode]
        );
        
        res.json({
            success: true,
            beneficiaryId: insertRes.rows[0].id,
            beneCode: beneCode,
            message: "Beneficiary added successfully"
        });
        
    } catch (e) {
        console.error('Beneficiary registration error:', e);
        res.status(500).json({ success: false, message: e.message });
    }
});

// Get beneficiary list
router.post('/beneficiary/list', async (req, res) => {
    const retailerId = req.user?.id || 1;
    
    try {
        const { senderMobile } = req.body;

        console.log('Checking sender:', senderMobile);

        // Get remitter from dmt_remitters table
        const remRes = await db.query(
              `SELECT id, kyc_status, sender_registered, first_name, last_name,
                    monthly_limit, monthly_used, aadhar_no
             FROM dmt_remitters
             WHERE retailer_id = $1 AND mobile = $2`,
            [retailerId, senderMobile]
        );
        
        // If sender doesn't exist in dmt_remitters
        if (remRes.rows.length === 0) {
            console.log('Sender not found in database');
            return res.json({
                success: true,
                data: {
                    beneficiaries: [],
                    isKycDone: 0,
                    senderRegistered: false,
                    senderExists: false,  // Important flag
                    exists: false,        // Alternative flag
                    message: 'Sender not found'
                }
            });
        }
        
        const remitter = remRes.rows[0];
        const remitterId = remitter.id;
        const kycStatus = remitter.kyc_status;
        const senderRegistered = remitter.sender_registered;
        const senderName = `${remitter.first_name || ''} ${remitter.last_name || ''}`.trim() || 'Sender';
        
        const isKycDone = (kycStatus === 'completed' || kycStatus === 'COMPLETED') ? 1 : 0;

        // Get beneficiaries from database
        const beneRes = await db.query(
            `SELECT id, account_holder_name as benename, 
                    account_number as accountno, ifsc_code as ifsc,
                    verified as beneVerify, bene_code as benecode,
                    bank_name, account_type
             FROM dmt_beneficiaries
             WHERE remitter_id = $1 AND is_active = true`,
            [remitterId]
        );

        res.json({
            success: true,
            data: {
                beneficiaries: beneRes.rows,
                isKycDone: isKycDone,
                senderRegistered: senderRegistered,
                senderExists: true,  // Important flag
                exists: true,        // Alternative flag
                senderId: remitterId,
                senderName: senderName,
                accountNumber: remitter.aadhar_no || 'Not added',
                ifscCode: 'Not added',
                monthlyLimit: parseFloat(remitter.monthly_limit) || 25000,
                monthlyUsed: parseFloat(remitter.monthly_used) || 0,
                kycStatus: kycStatus
            }
        });
        
    } catch (e) {
        console.error('Beneficiary list error:', e);
        res.status(500).json({ success: false, message: e.message });
    }
});

// ============ DMT TRANSACTION ============
router.post('/transaction', async (req, res) => {
    const retailerId = req.user?.id || 1;
    
    try {
        const { senderMobile, beneficiaryId, amount, txnMode, otp } = req.body;

        // Get remitter
        const remRes = await db.query(
            `SELECT id, monthly_limit, monthly_used
             FROM dmt_remitters
             WHERE retailer_id = $1 AND mobile = $2 AND is_active = true`,
            [retailerId, senderMobile]
        );
        
        if (!remRes.rows.length) {
            throw new Error('Remitter not found');
        }
        
        const remitter = remRes.rows[0];

        // Check monthly limit
        const remainingLimit = parseFloat(remitter.monthly_limit) - parseFloat(remitter.monthly_used);
        if (parseFloat(amount) > remainingLimit) {
            throw new Error(`Monthly limit exceeded. Remaining: ₹${remainingLimit}`);
        }

        // Get beneficiary
        const beneRes = await db.query(
            `SELECT id FROM dmt_beneficiaries
             WHERE id = $1 AND remitter_id = $2 AND is_active = true`,
            [beneficiaryId, remitter.id]
        );
        
        if (!beneRes.rows.length) {
            throw new Error('Beneficiary not found');
        }

        const rrn = `RRN${Date.now()}${Math.floor(Math.random() * 1000)}`;
        const txnId = `TXN${Date.now()}${Math.floor(Math.random() * 1000)}`;

        // Save transaction
        await db.query(
            `INSERT INTO dmt_transactions
                (retailer_id, remitter_id, beneficiary_id, amount,
                 utr_number, iyda_txn_id, gateway_txn_id,
                 transfer_mode, status, rrn, txn_mode)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
            [retailerId, remitter.id, beneficiaryId, amount,
             rrn, txnId, txnId,
             txnMode || 'IMPS', 'success', rrn, txnMode || 'IMPS']
        );

        // Update monthly_used
        await db.query(
            `UPDATE dmt_remitters
             SET monthly_used = monthly_used + $1, updated_at = now()
             WHERE id = $2`,
            [amount, remitter.id]
        );

        res.json({
            success: true,
            status: 'success',
            txnId: txnId,
            rrn: rrn,
            message: "Transaction successful",
            amount: amount
        });
        
    } catch (e) {
        console.error('Transaction error:', e);
        res.status(500).json({ success: false, message: e.message });
    }
});

module.exports = router;