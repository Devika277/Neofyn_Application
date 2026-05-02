// services/recharge/bbpsService.js
const { v4: uuidv4 } = require('uuid');
const db = require('../../config/db');
const logger = require('../../utils/logger');

// Dummy bill data generator
const DUMMY_BILLS = {
  ELECTRICITY: {
    billerId: "BBPS_ELEC_001",
    billerName: "City Power Distribution Ltd",
    category: "ELECTRICITY",
    billAmount: 1542.50,
    lateFee: 50.00,
    totalAmount: 1592.50,
  },
  WATER: {
    billerId: "BBPS_WTR_002",
    billerName: "Municipal Water Supply Board",
    category: "WATER",
    billAmount: 850.00,
    lateFee: 25.00,
    totalAmount: 875.00,
  },
  GAS: {
    billerId: "BBPS_GAS_003",
    billerName: "City Gas Network",
    category: "GAS",
    billAmount: 2340.75,
    lateFee: 100.00,
    totalAmount: 2440.75,
  },
  TELECOM: {
    billerId: "BBPS_TEL_004",
    billerName: "Fast Broadband Services",
    category: "TELECOM",
    billAmount: 999.00,
    lateFee: 0,
    totalAmount: 999.00,
  }
};

function generateBillNumber() {
  return `BILL${Date.now()}${Math.floor(Math.random() * 10000)}`;
}

function generateCustomerName(customerId) {
  const names = ["Rahul Sharma", "Priya Patel", "Amit Kumar", "Neha Singh", "Test User"];
  const index = parseInt(customerId?.slice(-2) || "0") % names.length;
  return names[index];
}

// Main fetch bill function
async function fetchBBPSBill(userId, billData) {
  const { serviceType, customerId, isTestMode = true } = billData;
  
  logger.info(`Fetching ${serviceType} bill for customer ${customerId}, user: ${userId}`);
  
  try {
    const dummyConfig = DUMMY_BILLS[serviceType] || DUMMY_BILLS.ELECTRICITY;
    const billNumber = generateBillNumber();
    const dueDate = new Date();
    dueDate.setDate(dueDate.getDate() + 15);
    const customerName = generateCustomerName(customerId);
    
    // Randomize amount
    let billAmount = dummyConfig.billAmount;
    if (serviceType === 'ELECTRICITY') {
      billAmount = Math.floor(Math.random() * 3000) + 500;
    }
    
    const dummyResponse = {
      success: true,
      isDummyData: true,
      message: "Bill fetched successfully (Test Data)",
      data: {
        id: Date.now(),
        billerId: dummyConfig.billerId,
        billerName: dummyConfig.billerName,
        serviceType: serviceType,
        customerId: customerId,
        customerName: customerName,
        consumerNumber: customerId,
        billNumber: billNumber,
        billAmount: billAmount,
        lateFee: dummyConfig.lateFee,
        totalAmount: billAmount + dummyConfig.lateFee,
        dueDate: dueDate.toISOString(),
        billDate: new Date().toISOString(),
        billPeriod: "Current Month",
        status: "PENDING",
        isPaid: false
      }
    };
    
    // Save to database
    try {
      await saveBillToDatabase({
        userId,
        serviceType,
        ...dummyResponse.data,
        isTestData: true
      });
    } catch (dbError) {
      logger.warn('Could not save bill to DB:', dbError.message);
    }
    
    return dummyResponse;
    
  } catch (error) {
    logger.error('fetchBBPSBill error:', error);
    return {
      success: true,
      isDummyData: true,
      isFallback: true,
      message: "Bill generated from fallback data",
      data: generateFallbackBill(serviceType, customerId)
    };
  }
}

function generateFallbackBill(serviceType, customerId) {
  return {
    billerId: `FALLBACK_${serviceType}`,
    billerName: `${serviceType} Bill Service`,
    serviceType: serviceType,
    customerId: customerId,
    customerName: "Customer",
    billNumber: `FALLBACK_${Date.now()}`,
    billAmount: 1000,
    totalAmount: 1000,
    dueDate: new Date(Date.now() + 15 * 24 * 60 * 60 * 1000).toISOString(),
    status: "PENDING"
  };
}

// ✅ ADD THIS FUNCTION - Save bill to database
async function saveBillToDatabase(billData) {
  const query = `
    INSERT INTO bills (
      user_id, service_type, biller_id, biller_name, customer_id,
      customer_name, bill_number, bill_amount, late_fee, total_amount, 
      due_date, bill_date, bill_period, bill_status, additional_info, is_test_data
    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)
    RETURNING id
  `;
  
  const values = [
    billData.userId,
    billData.serviceType,
    billData.billerId,
    billData.billerName,
    billData.customerId,
    billData.customerName,
    billData.billNumber,
    billData.billAmount,
    billData.lateFee || 0,
    billData.totalAmount,
    new Date(billData.dueDate),
    new Date(billData.billDate || Date.now()),
    billData.billPeriod,
    billData.status || 'PENDING',
    JSON.stringify(billData.additionalInfo || {}),
    billData.isTestData || true
  ];
  
  const result = await db.query(query, values);
  return result.rows[0].id;
}

// ✅ ADD THIS FUNCTION - Update bill status
async function updateBillStatus(billId, status, transactionId) {
  try {
    logger.info(`Updating bill ${billId} status to ${status}, transaction: ${transactionId}`);
    
    const query = `
      UPDATE bills 
      SET bill_status = $1, 
          transaction_id = $2, 
          updated_at = NOW()
      WHERE id = $3
      RETURNING *
    `;
    
    const values = [status, transactionId, billId];
    const result = await db.query(query, values);
    
    if (result.rows.length === 0) {
      logger.warn(`Bill ${billId} not found for status update`);
      return null;
    }
    
    logger.info(`Bill ${billId} status updated to ${status}`);
    return result.rows[0];
    
  } catch (error) {
    logger.error('Error updating bill status:', error);
    throw error;
  }
}

// ✅ ADD THIS FUNCTION - Get customer bills
async function getCustomerBills(userId, serviceType = null, limit = 50, offset = 0) {
  try {
    let query = `
      SELECT id, service_type, biller_name, customer_id, bill_number,
             bill_amount, total_amount, due_date, bill_date, bill_period,
             bill_status, is_test_data, created_at
      FROM bills
      WHERE user_id = $1
    `;
    const params = [userId];
    let paramIndex = 2;
    
    if (serviceType && serviceType !== 'all' && serviceType !== 'undefined') {
      query += ` AND service_type = $${paramIndex}`;
      params.push(serviceType.toUpperCase());
      paramIndex++;
    }
    
    query += ` ORDER BY created_at DESC LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`;
    params.push(limit, offset);
    
    const result = await db.query(query, params);
    
    const countResult = await db.query(
      `SELECT COUNT(*) FROM bills WHERE user_id = $1 ${serviceType && serviceType !== 'all' && serviceType !== 'undefined' ? 'AND service_type = $2' : ''}`,
      serviceType && serviceType !== 'all' && serviceType !== 'undefined' ? [userId, serviceType.toUpperCase()] : [userId]
    );
    
    return {
      success: true,
      bills: result.rows,
      total: parseInt(countResult.rows[0].count),
      limit,
      offset
    };
    
  } catch (error) {
    logger.error('Error fetching customer bills:', error);
    return {
      success: false,
      bills: [],
      total: 0,
      message: error.message
    };
  }
}

// ✅ ADD THIS FUNCTION - Get available services
async function getAvailableServices() {
  try {
    const result = await db.query(
      `SELECT name, display_name, category, icon, is_active 
       FROM services 
       WHERE is_active = true 
       ORDER BY category, display_name`
    );
    
    if (result.rows.length > 0) {
      return result.rows;
    }
    
    return [
      { name: 'ELECTRICITY', display_name: 'Electricity Bill', category: 'UTILITY', icon: '⚡', is_active: true },
      { name: 'WATER', display_name: 'Water Bill', category: 'UTILITY', icon: '💧', is_active: true },
      { name: 'GAS', display_name: 'Gas Bill', category: 'UTILITY', icon: '🔥', is_active: true },
      { name: 'TELECOM', display_name: 'Broadband Bill', category: 'UTILITY', icon: '📡', is_active: true }
    ];
  } catch (error) {
    logger.error('Error fetching services:', error);
    return [
      { name: 'ELECTRICITY', display_name: 'Electricity Bill', category: 'UTILITY' },
      { name: 'WATER', display_name: 'Water Bill', category: 'UTILITY' },
      { name: 'GAS', display_name: 'Gas Bill', category: 'UTILITY' },
      { name: 'TELECOM', display_name: 'Broadband Bill', category: 'UTILITY' }
    ];
  }
}

// ✅ MAKE SURE ALL FUNCTIONS ARE EXPORTED
module.exports = {
  fetchBBPSBill,
  saveBillToDatabase,
  updateBillStatus,      // ← This was missing!
  getCustomerBills,      // ← This was missing!
  getAvailableServices,  // ← This was missing!
  DUMMY_BILLS
};