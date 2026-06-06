# AEPS Module Documentation (Flutter + Backend + Provider Integration)

## 1) Summary
This repo implements **AEPS (Aadhaar Enabled Payment System)** as a multi-layer flow:

1. **Flutter UI** collects merchant onboarding and transaction inputs.
2. **Flutter providers/services** call your **Node/Express backend**.
3. **Node/Express backend** integrates with the **VimoPay AEPS provider** (encrypted API) and persists results to DB tables.

---

## 2) High-level AEPS Flow

### A) Merchant Onboarding Flow
**Flutter**
- `AepsWrapperScreen` decides whether merchant registration is required.
- `MerchantRegistrationScreen` collects:
  - merchant personal data (name/dob/email/mobile/aadhaar/pan)
  - merchant shop/bank details
  - shop address + **GPS location** (lat/long)
  - state + district selection
- After registration, Flutter triggers OTP send + OTP verify.

**Backend**
- `POST /api/aeps/merchant/register` → creates `merchantRefId`, calls `aepsService.registerMerchant`, then saves merchant in DB.
- `POST /api/aeps/merchant/send-otp` → calls provider OTP send.
- `POST /api/aeps/merchant/verify-otp` → validates OTP, updates merchant verification status.

**Provider (VimoPay)**
- `authorizeuat` (token)
- `merchantonboarduat`
- `sendotpuat` / OTP validate endpoints (see note in service section)

---

### B) AEPS Transaction Flow (Cash Withdrawal / Balance / Mini Statement)
**Flutter**
- Transaction screens build an `AepsTransactionRequest`.
- `AepsProvider.executeTransaction(...)` calls backend `POST /api/aeps/transaction`.

**Backend**
- `POST /api/aeps/transaction`:
  - extracts userId (from request body/headers)
  - generates transaction reference (`txnRefId`)
  - calls `aepsService.aepsTransaction`
  - maps provider response → DB record
  - persists record using `saveAepsTransaction(...)` into `public.aeps_transactions`

**Provider (VimoPay)**
- `aepstransaction` (encrypted)

---

### C) Status and Webhook Callback
**Flutter** can query:
- `POST /api/aeps/transaction/status`

**Backend webhook**
- `POST /api/aeps/callback` receives provider callbacks and updates DB via `TransactionModel.updateStatus(...)`.

---

## 3) Flutter AEPS Files (and how they connect)

### 3.1 Screen: Routing / Entry
- **`my_app/lib/screens/aeps/aeps_wrapper_screen.dart`**
  - Gatekeeper UI:
    - if `provider.merchantId` is missing/empty → `MerchantRegistrationScreen`
    - else → `AepsDashboardScreen`
    - daily 2FA logic is present but commented out.

### 3.2 Screen: Merchant Registration + OTP UI
- **`my_app/lib/screens/aeps/merchant_registration_screen.dart`**
  - Loads states list: `context.read<AepsProvider>().getStateList()`
  - Captures GPS location via `LocationService`
  - Creates `MerchantRegistrationRequest` and calls:
    - `AepsProvider.registerMerchant(request)`
    - then `_sendOtp()` → `AepsProvider.sendOtp(merchantId, mobileNo)`
    - then `_verifyOtp()` → `AepsProvider.verifyOtp(merchantId, otp, merchantRefId)`

### 3.3 Provider: State + API orchestration
- **`my_app/lib/providers/aeps_provider.dart`**
  - Stores:
    - merchant info: `_merchantId`, `_merchantRefId`
    - auth info: `_authToken`, `_userId`
    - ip address and `pipe`
    - master data: `_states`, `_districts`, `_banks`
  - Persists auth token + userId to `SharedPreferences`.
  - Important methods:
    - `setAuthDetails(token, userId, merchantId, ...)`
    - `registerMerchant(...)` → saves merchant info to backend + local merchant state
    - `sendOtp(...)`, `verifyOtp(...)`
    - `executeTransaction(AepsTransactionRequest request)` → calls backend transaction endpoint
    - `performAepsTransaction(...)` → builds request from UI inputs

### 3.4 Flutter API client
- **`my_app/lib/services/AEPS/api_service.dart`**
  - Wraps backend endpoints defined in `ApiConfig`:
    - `getBankList`, `getStateList`, `getDistrictList`
    - `registerMerchant`, `sendOtp`, `verifyOtp`
    - `twoFactorAuth`
    - `aepsTransaction(request, token, userId)`
    - `getTransactionStatus`

### 3.5 Backend base URL + endpoint constants
- **`my_app/lib/config/api_config.dart`**
  - Defines backend base URL and all AEPS endpoint paths.

### 3.6 Models
- **`my_app/lib/models/aeps_models.dart`**
  - Contains `AepsTransactionRequest`, `TransactionResponse`, and merchant/bank/state/district models.

- **`my_app/lib/models/transaction_models.dart`**
  - Transaction response/types used by transaction UI.

---

## 4) Backend AEPS Files (and how they connect)

### 4.1 Express mounting
- **`my_app/neofyn-backend/app.js`** and **`my_app/neofyn-backend/server.js`**
  - Mount routes under:
    - `app.use('/api/aeps', aepsRoutes);`

### 4.2 AEPS router
- **`my_app/neofyn-backend/routes/aepsRoutes.js`**
  - Endpoints:
    - `GET /api/aeps/health`
    - `GET /api/aeps/banks`
    - `GET /api/aeps/states`
    - `POST /api/aeps/districts`
    - `POST /api/aeps/merchant/register`
    - `POST /api/aeps/merchant/send-otp`
    - `POST /api/aeps/merchant/verify-otp`
    - `GET /api/aeps/merchant/by-phone`
    - `POST /api/aeps/2fa`
    - `POST /api/aeps/transaction`
    - `POST /api/aeps/transaction/status`
    - `POST /api/aeps/callback`

### 4.3 Controller layer
- **`my_app/neofyn-backend/controllers/aepsControllers.js`**
  - Calls into service layer:
    - `aepsService.getBankList/getStateList/getDistrictList`
    - `aepsService.registerMerchant/sendOtp/verifyOtp/twoFactorAuth/aepsTransaction`
  - Persists transaction rows:
    - `saveAepsTransaction(dbRecord)` inserts into `public.aeps_transactions`
  - Handles provider callback:
    - `webhookCallback` updates transaction status via `TransactionModel.updateStatus(...)`

### 4.4 Service: VimoPay encrypted AEPS integration
- **`my_app/neofyn-backend/services/aepsService.js`**
  - Key components:
    - `authorize()` → obtains bearer token via `/aepsapi/api/signature/authorizeuat`
    - `makeRequest(...)` → adds headers + encrypts payload + decrypts response
  - Feature methods:
    - `getBankList()` → decrypts master response from `/masterapi/api/master/banklistuat`
    - `getStateList()` → decrypts `/masterapi/api/master/statelistuat`
    - `getDistrictList(stateCode)` → encrypted request/response to `/aepsapi/api/payment/acquiredistrictuat`
    - `registerMerchant(...)` → `/aepsapi/api/payment/merchantonboarduat`
    - `sendOtp(...)` → `/aepsapi/api/payment/sendotpuat` (supports `MOCK_OTP`)
    - `twoFactorAuth(...)` → `/aepsapi/api/payment/2fauat`
    - `aepsTransaction(...)` → `/aepsapi/api/payment/aepstransaction`
    - `transactionStatus(...)` → `/aepsapi/api/payment/transactionstatus`

### 4.5 Backend encryption utility
- **`my_app/neofyn-backend/services/encryptionService.js`**
  - Used by `aepsService.js`:
    - `prepareRequest(data)`
    - `decrypt(encryptedString)`
    - `parseResponse(...)`

### 4.6 Backend DB models
- **`my_app/neofyn-backend/models/Merchant.js`**
  - Merchant persistence and lookup (used by registration and `getMerchantByPhone`).

- **`my_app/neofyn-backend/models/Transaction.js`**
  - Transaction status update for webhook callbacks.

---

## 5) Endpoint Mapping (Flutter → Backend → Provider)

| Flutter backend call | Backend route | Backend service method | Provider endpoint |
|---|---|---|---|
| `/api/aeps/banks` | `GET /banks` | `aepsService.getBankList` | `/masterapi/api/master/banklistuat` |
| `/api/aeps/states` | `GET /states` | `aepsService.getStateList` | `/masterapi/api/master/statelistuat` |
| `/api/aeps/districts` | `POST /districts` | `aepsService.getDistrictList` | `/aepsapi/api/payment/acquiredistrictuat` |
| `/api/aeps/merchant/register` | `POST /merchant/register` | `registerMerchant` | `/aepsapi/api/payment/merchantonboarduat` |
| `/api/aeps/merchant/send-otp` | `POST /merchant/send-otp` | `sendOtp` | `/aepsapi/api/payment/sendotpuat` |
| `/api/aeps/merchant/verify-otp` | `POST /merchant/verify-otp` | (verify OTP in service/controller) | OTP validate endpoint (depends on service wiring) |
| `/api/aeps/transaction` | `POST /transaction` | `aepsTransaction` | `/aepsapi/api/payment/aepstransaction` |
| `/api/aeps/transaction/status` | `POST /transaction/status` | `transactionStatus` | `/aepsapi/api/payment/transactionstatus` |
| webhook | `POST /callback` | `webhookCallback` | provider→your-callback |

---

## 6) AEPS ↔ Wallet/Other Modules Integration
- The app’s **home UI** includes AEPS as a service.
- Wallet data fetch (AEPS wallet balance) is handled by wallet provider + wallet routes.
- AEPS transaction records are stored separately in `public.aeps_transactions` and updated on callback.

---

## 7) Notes / Potential Code Caveats
- `aepsService.js` contains mixed/duplicate OTP verification code paths (some earlier blocks are commented/inconsistent). The main expected flow is:
  - merchant registration
  - OTP send
  - OTP verify
  - merchant verified
  - transaction authorization + encrypted call

This document describes the implemented routing and integration structure as currently present in the repo.

