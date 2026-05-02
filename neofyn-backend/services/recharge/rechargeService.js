const { v4: uuidv4 } = require('uuid');
const db = require('../../config/db'); 
const logger = require('../../utils/logger');
const walletService = require('./walletService');
const providerRouter = require('./providerRouter');
const commissionEngine = require('./commissionEngine');

class RechargeService {
    async processRecharge(userId, rechargeData, idempotencyKey = null) {
        const { mobile, operator, circle, amount, testMode } = rechargeData;
        
        const client = await db.connect();
        let transactionId = null;

        try {
            // Validation
            if (!mobile || !operator || !circle || !amount) {
                throw new Error('Missing required fields');
            }
            if (amount <= 0) {
                throw new Error('Amount must be greater than 0');
            }

            logger.info(`Processing recharge for user ${userId}, amount: ₹${amount}`);

            // Check balance first (outside transaction for efficiency)
            const balance = await walletService.getBalance(userId);
            if (balance < amount) {
                // Create a failed transaction record WITHOUT using transaction
                const insertResult = await db.query(
                    `INSERT INTO transactions
                     (user_id, type, mobile, operator, circle, plan_amount, status, idempotency_key, api_response, created_at, updated_at)
                     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW(), NOW())
                     RETURNING id`,
                    [userId, 'MOBILE_RECHARGE', mobile, operator, circle, amount, 'failed', idempotencyKey || null, 
                     JSON.stringify({ error: 'INSUFFICIENT_BALANCE', message: `Insufficient balance. Available: ₹${balance}, Required: ₹${amount}` })]
                );
                transactionId = insertResult.rows[0].id;
                
                logger.info(`Transaction ${transactionId} failed - Insufficient balance`);
                return {
                    success: false,
                    message: `Insufficient balance. Available: ₹${balance}, Required: ₹${amount}`,
                    transactionId: transactionId,
                    provider: null,
                    refunded: false,
                    errorCode: 'INSUFFICIENT_BALANCE',
                    details: {
                        available: balance,
                        required: amount,
                        shortfall: amount - balance
                    }
                };
            }

            // Start transaction for successful flow
            await client.query('BEGIN');
            
            // Create pending transaction
            const insertResult = await client.query(
                `INSERT INTO transactions
                 (user_id, type, mobile, operator, circle, plan_amount, status, idempotency_key, created_at, updated_at)
                 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW(), NOW())
                 RETURNING id`,
                [userId, 'MOBILE_RECHARGE', mobile, operator, circle, amount, 'pending', idempotencyKey || null]
            );
            transactionId = insertResult.rows[0].id;
            logger.info(`Created pending transaction ${transactionId}`);

            // Deduct wallet
            const deductResult = await walletService.deductMoney(
                userId, amount, `Mobile recharge for ${mobile}`, transactionId
            );
            logger.info(`Wallet deducted. New balance: ₹${deductResult.newBalance}`);

            // Process with provider (mock for now)
            let providerResponse = null;
            let status = 'failed';
            let providerTxnId = null;
            let errorMessage = null;

            try {
                // Mock provider call - replace with actual provider integration
                if (testMode || process.env.NODE_ENV === 'development') {
                    // Mock success for testing
                    providerResponse = {
                        status: 'success',
                        provider_txn_id: `VI${Date.now()}${Math.floor(Math.random() * 10000)}`,
                        message: 'Recharge successful'
                    };
                } else {
                    // Actual provider call
                    providerResponse = await providerRouter.routeRecharge({
                        mobile, operator, circle, amount,
                        transaction_id: transactionId,
                        user_id: userId,
                        testMode
                    });
                }
                
                status = providerResponse.status === 'success' ? 'success' : 
                         providerResponse.status === 'pending' ? 'pending' : 'failed';
                providerTxnId = providerResponse.provider_txn_id;
                
                if (status === 'failed') {
                    errorMessage = providerResponse.message || 'Provider returned failure';
                }
                
            } catch (providerError) {
                logger.error('Provider error:', providerError.message);
                status = 'failed';
                errorMessage = providerError.message || 'Provider call failed';
            }

            // Update transaction with result
            await client.query(
                `UPDATE transactions
                 SET status = $1, 
                     provider_txn_id = $2, 
                     api_response = $3, 
                     updated_at = NOW()
                 WHERE id = $4`,
                [status, providerTxnId, JSON.stringify({ message: errorMessage || 'Success' }), transactionId]
            );

            // Handle refund if failed
            let refunded = false;
            if (status === 'failed') {
                logger.info(`Transaction failed, initiating refund for ${transactionId}`);
                const refundResult = await walletService.addMoney(
                    userId, amount, `Refund for failed recharge transaction ${transactionId} - ${errorMessage}`, null, transactionId
                );
                refunded = true;
                logger.info(`Refund complete. New balance: ₹${refundResult.newBalance}`);
            }

            // Calculate commission for success
            if (status === 'success') {
                await commissionEngine.calculate({
                    userId: userId,
                    serviceType: 'mobile',
                    providerId: null,
                    txnAmount: amount,
                    transactionRef: transactionId.toString()
                }).catch(err => {
                    logger.error(`Commission calculation failed: ${err.message}`);
                });
            }

            await client.query('COMMIT');

            // Build response message
            let message;
            if (status === 'success') message = 'Recharge successful';
            else if (status === 'pending') message = 'Recharge is processing';
            else message = `Recharge failed: ${errorMessage || 'Unknown error'}`;

            return {
                success: status === 'success',
                message: message,
                transactionId: transactionId,
                provider: providerTxnId,
                refunded: refunded,
                ...(status === 'failed' && { errorCode: 'PROVIDER_FAILED' })
            };

        } catch (error) {
            // Rollback transaction if it was started
            try {
                await client.query('ROLLBACK');
            } catch (rollbackError) {
                logger.error('Rollback error:', rollbackError.message);
            }
            
            logger.error(`RechargeService: Error processing recharge`, { 
                error: error.message, 
                stack: error.stack 
            });
            
            // Try to save failed transaction outside of transaction
            if (!transactionId) {
                try {
                    const insertResult = await db.query(
                        `INSERT INTO transactions
                         (user_id, type, mobile, operator, circle, plan_amount, status, api_response, created_at, updated_at)
                         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW(), NOW())
                         RETURNING id`,
                        [userId, 'MOBILE_RECHARGE', mobile, operator, circle, amount, 'failed', 
                         JSON.stringify({ error: error.message })]
                    );
                    transactionId = insertResult.rows[0].id;
                } catch (dbError) {
                    logger.error('Failed to save error transaction:', dbError.message);
                }
            }
            
            return {
                success: false,
                message: error.message || 'Failed to process recharge',
                transactionId: transactionId,
                provider: null,
                refunded: false,
                errorCode: 'PROCESSING_ERROR'
            };
        } finally {
            client.release();
        }
    }

    async getUserHistory(userId, limit = 50, offset = 0) {
        try {
            const result = await db.query(
                `SELECT id, mobile, operator, circle, plan_amount as amount,
                        status, provider_txn_id, created_at, updated_at,
                        api_response
                 FROM transactions
                 WHERE user_id = $1 AND type = 'MOBILE_RECHARGE'
                 ORDER BY created_at DESC
                 LIMIT $2 OFFSET $3`,
                [userId, limit, offset]
            );
            return result.rows;
        } catch (error) {
            logger.error(`Error fetching user history:`, error.message);
            return [];
        }
    }

    async getAllRecharges(filters = {}, limit = 50, offset = 0) {
        try {
            let whereClause = "WHERE t.type = 'MOBILE_RECHARGE'";
            const params = [];
            let paramIndex = 1;

            if (filters.status) {
                whereClause += ` AND t.status = $${paramIndex}`;
                params.push(filters.status);
                paramIndex++;
            }
            if (filters.operator) {
                whereClause += ` AND t.operator = $${paramIndex}`;
                params.push(filters.operator);
                paramIndex++;
            }
            if (filters.search) {
                whereClause += ` AND t.mobile ILIKE $${paramIndex}`;
                params.push(`%${filters.search}%`);
                paramIndex++;
            }

            const countQuery = await db.query(`SELECT COUNT(*) FROM transactions t ${whereClause}`, params);
            const result = await db.query(
                `SELECT t.*,
                        CONCAT(u.first_name, ' ', u.last_name) AS user_name,
                        u.email,
                        u.phone AS user_mobile
                 FROM transactions t
                 JOIN users u ON u.id = t.user_id
                 ${whereClause}
                 ORDER BY t.created_at DESC
                 LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`,
                [...params, limit, offset]
            );
            return {
                transactions: result.rows,
                total: parseInt(countQuery.rows[0].count),
                limit,
                offset
            };
        } catch (error) {
            logger.error(`Error fetching all recharges:`, error.message);
            throw error;
        }
    }
}

module.exports = new RechargeService();