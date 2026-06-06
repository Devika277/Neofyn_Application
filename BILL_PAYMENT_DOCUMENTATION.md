# Bill Payment (BBPS) Module Documentation

This document explains how **Bill Payment** / **BBPS** is implemented across:
- **Frontend (Flutter)**
- **Providers/Services (Flutter)**
- **Backend (Node/Express)**
- **Provider Integration** (VimoPay / encrypted requests)

---

## 1) What exists in the repo

### Frontend (Flutter)
- `my_app/lib/screens/bbps_payment_screen.dart`
- `my_app/lib/services/Recharges/bbps_service.dart`
- `my_app/lib/models/bbps_models.dart`

### Backend (Node)
- `my_app/neofyn-backend/routes/bbpsRoutes.js`
- `my_app/neofyn-backend/controllers/bbpsController.js`
- `my_app/neofyn-backend/services/recharge/bbpsService.js`  *(provider calls + data mapping)*
- `my_app/neofyn-backend/services/vimoPayService.js` *(common provider/VimoPay functionality)*
- `my_app/neofyn-backend/services/recharge/rechargeService.js` *(shared patterns used by controller/service)*

### Shared / infrastructure
- `my_app/neofyn-backend/server.js` mounts `/api/bbps`
- `my_app/neofyn-backend/services/encryptionService.js` for encrypt/decrypt patterns (when used by BBPS service)

---

## 2) End-to-End flow (Frontend → Backend → Provider)

### Step A — User selects bill category/biller
**Flutter UI**: `bbps_payment_screen.dart`
- Static data for categories/billers in the screen (at least partially)
- Or can also fetch lists from backend depending on how the screen is currently wired

### Step B — Fetch bill details
**Frontend**: `BbpsService.fetchBill(...)`
- Calls: `POST /api/bbps/fetch-bill`
- Sends: `billerId` / `serviceType` + `consumerNumber` (and optional amount)

**Backend**:
- Route: `POST /api/bbps/fetch-bill`
- Controller: `bbpsController.fetchBill`
- Service: `bbpsService.fetchBBPSBill(...)`

**Provider (VimoPay)**
- Service encrypts request (if required)
- Calls VimoPay endpoint
- Decrypts response
- Controller returns mapped JSON to Flutter

### Step C — Pay bill
**Frontend**: `BbpsService.payBill(...)`
- Calls: `POST /api/bbps/pay-bill`
- Sends: `billId` + `amount` + `consumerNumber`/`customerId` + payment context

**Backend**:
- Route: `POST /api/bbps/pay-bill`
- Controller: `bbpsController.payBill`
- For now, the controller code indicates a “mark as success” path until PaymentService is integrated.

### Step D — Payment status
**Frontend**: may poll status
- Calls: `GET /api/bbps/status/:merchantRefId` or `getBillHistory`

**Backend**:
- Route: `GET /api/bbps/status/:merchantRefId`
- Controller: `bbpsController.checkStatus`

---

## 3) Backend wiring (Routes)

### `my_app/neofyn-backend/server.js`
- Mounts:
  - `app.use('/api/bbps', require('./routes/bbpsRoutes'));`

### `my_app/neofyn-backend/routes/bbpsRoutes.js`
Routes defined:
- `GET    /api/bbps/categories` (protected)
- `GET    /api/bbps/states`
- `GET    /api/bbps/billers`
- `POST   /api/bbps/fetch-bill` (protected)
- `POST   /api/bbps/pay-bill` (protected)
- `GET    /api/bbps/bill-history` (protected)
- `GET    /api/bbps/status/:merchantRefId`

> Note: The repository contains both `fetchBill` and `payBill` endpoints; Flutter/bbps_service uses `fetch-bill`, `pay-bill`, and `status` endpoints.

---

## 4) Backend business logic (Controller)

### `my_app/neofyn-backend/controllers/bbpsController.js`
Main responsibilities:
- Validate request payload
- Determine `userId` (often from `req.user.id` when `protect` middleware is applied)
- Call provider service layer:
  - `bbpsService.fetchBBPSBill(userId, ...)`
  - `bbpsService.updateBillStatus(...)`
- Return JSON in a shape Flutter expects

Key functions (based on search hits):
- `getCategories(req,res)`
- `getStates(req,res)`
- `getBillers(req,res)`
- `fetchBill(req,res)`
- `payBill(req,res)`
- `getBillHistory(req,res)`
- `getServices(req,res)`
- `checkStatus(req,res)`

---

## 5) Provider integration (Service)

### `my_app/neofyn-backend/services/recharge/bbpsService.js`
Responsibilities:
- Build and encrypt provider request
- Call VimoPay / provider endpoints
- Decrypt provider response
- Normalize response into internal format used by controller
- Update bill/payment status in DB (via db queries or shared models)

(Exact provider endpoint mapping depends on what’s inside this file; the controller already calls these service methods.)

### `my_app/neofyn-backend/services/vimoPayService.js`
Common helper for VimoPay requests, including base URL and request patterns.

---

## 6) Frontend: Flutter files and their roles

### `my_app/lib/screens/bbps_payment_screen.dart`
The UI implements (based on file comments):
- Category → Biller selection
- Consumer number input
- Fetch Bill
- Review bill details + amount
- Pay Now
- Success/Failure UI

### `my_app/lib/services/Recharges/bbps_service.dart`
API client functions for BBPS.
- Fetch categories/states/billers (depending on flow)
- `fetchBill(...)` → `POST /api/bbps/fetch-bill`
- `payBill(...)` → `POST /api/bbps/pay-bill`
- `checkStatus(...)` → `GET /api/bbps/status/:merchantRefId`

### `my_app/lib/models/bbps_models.dart`
Data models used by BBPS:
- `Biller`
- `BillerParam`
- `FetchBillResult` / mapped provider data structures

---

## 7) Endpoint mapping (Frontend → Backend)

| Flutter call | Backend route | Notes |
|---|---|---|
| fetchBill(...) | `POST /api/bbps/fetch-bill` | sends billerId/serviceType + consumerNumber |
| payBill(...) | `POST /api/bbps/pay-bill` | sends billId + amount + consumer/customer |
| checkStatus(...) | `GET /api/bbps/status/:merchantRefId` | merchantRefId from payment initiation |
| bill history | `GET /api/bbps/bill-history` | requires protect |
| categories/states/billers | `GET /api/bbps/...` | used to populate dropdowns |

---

## 8) Documentation gaps / where to extend
- If you want this doc to include **exact VimoPay endpoints** and **exact encrypted request fields**, the next step is to open:
  - `my_app/neofyn-backend/services/recharge/bbpsService.js`
  - `my_app/neofyn-backend/services/vimoPayService.js`
  - `my_app/lib/services/Recharges/bbps_service.dart`
  - (optional) `my_app/lib/screens/bbps_payment_screen.dart`

This current document focuses on the connection structure and the backend routes/controller responsibilities already present in the repo.

