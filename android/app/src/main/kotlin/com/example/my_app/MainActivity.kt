package com.example.my_app

import android.content.Intent
import android.os.Bundle
import android.util.Log                          // ← THIS was missing
import com.vimopay.matm.presentation.MatmStatusActivity
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.UUID

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.my_app/matm"
    private var pendingResult: MethodChannel.Result? = null
    private val REQUEST_CODE_MATM = 1001

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                // Extract merchantId sent from Flutter
                val merchantId = call.argument<String>("merchantId") ?: ""

                if (merchantId.isEmpty()) {
                    result.error("MISSING_MERCHANT_ID", "merchantId is required", null)
                    return@setMethodCallHandler
                }

                when (call.method) {
                    "startBalanceEnquiry" -> {
                        pendingResult = result
                        launchMatm(
                            txnCode = "BE",
                            remarks = "Balance Enquiry",
                            amount = "0",
                            merchantId = merchantId
                        )
                    }
                    "startCashWithdrawal" -> {
                        val amount = call.argument<String>("amount") ?: "0"
                        pendingResult = result
                        launchMatm(
                            txnCode = "CW",
                            remarks = "Cash Withdrawal",
                            amount = amount,
                            merchantId = merchantId
                        )
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun launchMatm(
        txnCode: String,
        remarks: String,
        amount: String,
        merchantId: String          // ← now dynamic, from AEPS registration
    ) {
        // Keys come from BuildConfig (local.properties) — never hardcoded
        Log.d("MATM_DEBUG", "txnCode=$txnCode | merchantId=$merchantId | amount=$amount")

        val intent = Intent(this, MatmStatusActivity::class.java).apply {
            putExtra("secretKey",        BuildConfig.MATM_SECRET_KEY)
            putExtra("saltKey",          BuildConfig.MATM_SALT_KEY)
            putExtra("encryptDecryptKey",BuildConfig.MATM_ENCRYPT_KEY)
            putExtra("userId",           BuildConfig.MATM_USER_ID)
            putExtra("merchantId",       merchantId)          // ← from AEPS DB
            putExtra("pipe",             "1")
            putExtra("txnCode",          txnCode)
            putExtra("merchantRefId",    UUID.randomUUID().toString())
            putExtra("remarks",          remarks)
            putExtra("amount",           amount)
            putExtra("lat",              "28.6139")           // replace with real GPS later
            putExtra("long",             "77.2090")
        }
        startActivityForResult(intent, REQUEST_CODE_MATM)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
    super.onActivityResult(requestCode, resultCode, data)
    if (requestCode == REQUEST_CODE_MATM) {
        // ── Dump EVERYTHING from the intent for debugging ──────────────
        Log.d("MATM_DEBUG", "resultCode=$resultCode")
        data?.extras?.keySet()?.forEach { key ->
            Log.d("MATM_DEBUG", "  $key = ${data.extras?.get(key)}")
        }
        // ───────────────────────────────────────────────────────────────

        when (resultCode) {
            RESULT_OK -> {
                val response = data?.getStringExtra("response") ?: ""
                Log.d("MATM_DEBUG", "SUCCESS: $response")
                pendingResult?.success(response)
            }
            RESULT_CANCELED -> {
                val error = data?.getStringExtra("error")
                    ?: data?.getStringExtra("message")
                    ?: data?.getStringExtra("msg")
                    ?: data?.getStringExtra("status")
                    ?: "Cancelled"
                Log.d("MATM_DEBUG", "CANCELLED/ERROR: $error")
                pendingResult?.error("MATM_ERROR", error, null)
            }
        }
        pendingResult = null
    }
}
}


