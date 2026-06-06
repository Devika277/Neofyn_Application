# Login Screen + Backend Authentication Flow (Neofyn)

This document explains:
1) What happens on the **Flutter login screen**
2) Which **backend endpoints/services** handle login
3) How the backend uses **JWT + database tables**
4) Related database schema objects (based on code + migration file references available in repo)

---

## 1. Mobile UI (Flutter): `lib/screens/login_screen.dart`

### 1.1 User enters credentials
- Phone: `_phoneController`
- Password: `_passwordController`
- When user taps the CTA button (“Log in”), the screen calls ` _login()`.

### 1.2 Login API call
`_login()` sends a POST request to:

- **Endpoint**: `POST {ApiConfig.baseUrl}/api/auth/login`

- **Payload** (JSON):
```json
{
  "phone": "<phone>",
  "password": "<password>"
}
```

- **Headers**: `Content-Type: application/json`

### 1.3 Response parsing / token extraction
The UI tries to locate a JWT token from multiple possible response shapes:
- `data['token']`
- `data['data']['token']`
- `data['accessToken']`
- `data['data'] == '<token>'` (string)

If it finds a token, it persists it via:
- `FlutterSecureStorage` key: **`jwt_token`**

It also stores additional values in `SharedPreferences`:
- `userId`, `name`, `phone`, `accessToken`

### 1.4 Post-login initialization (AEPS + Wallet)
After storing token:
- Updates AEPS provider auth details:
  - `AepsProvider.setAuthDetails(token, userId, merchantId, mobileNo)`
- Updates Wallet provider user id:
  - `WalletProvider.setUserId(userId)`

Then it fetches merchant data:
- **Endpoint**: `GET {baseUrl}/api/aeps/merchant/by-phone?phone=<phone>`
- If success, it updates AEPS merchant fields + re-calls `setAuthDetails()` with `merchantId`.

### 1.5 Navigation
On success, it navigates to:
- `UserHomeScreen()` (via `Navigator.pushReplacement`).

---

## 2. Backend routing (Express): `neofyn-backend/server.js` and `routes/authRoutes.js`

### 2.1 Express server registers auth routes
In:
- `my_app/neofyn-backend/server.js`

The server mounts:
- `app.use('/api/auth', authRoutes);`

So the login endpoint is effectively:
- `POST /api/auth/login`

### 2.2 Auth Router: `neofyn-backend/routes/authRoutes.js`
Defines:
- `router.post('/register', register)`
- `router.post('/login', login)`

It also defines a token-cache endpoint:
- `POST /api/auth/token`

---

## 3. Backend controller: `neofyn-backend/controllers/authController.js`

### 3.1 `exports.login`
This is the handler for `POST /api/auth/login`.

#### Input validation
Expected JSON body:
- `phone`
- `password`

If missing, returns `400` with:
- `message: 'Phone number and password are required'`

#### User lookup
It queries:
- `SELECT * FROM users WHERE phone = $1`

#### Password verification
- Password is stored as bcrypt hash in DB.
- It verifies via:
  - `bcrypt.compare(password, user.password)`

On failures:
- User not found: `401 Invalid credentials`
- Password mismatch: `401 Invalid credentials`

#### Role checks
If user exists but role indicates account not active:
- `role === 'pending'` → `403 Account pending approval`
- `role === 'rejected'` → `403 Application not approved`

#### Token generation
On success it generates:
- `accessToken = generateAccessToken(user)`
- `refreshToken = generateRefreshToken(user)`

and inserts refresh token record into DB:
- `INSERT INTO refresh_tokens (user_id, token, expires_at) ...`

#### Login success response
Returns `200` JSON containing:
- `success: true`
- `message: 'Login successful'`
- `user: { id, name, email, phone, role }`
- `accessToken`
- `refreshToken`

---

## 4. JWT creation: `neofyn-backend/utils/token.js`

### 4.1 `generateAccessToken(user)`
Uses:
- `process.env.JWT_SECRET`
- signs minimal payload:
```js
{ id, email, phone, role }
```
- expiry: `7d`

### 4.2 `generateRefreshToken(user)`
Also uses `JWT_SECRET` (same env secret in this codebase) and signs:
```js
{ id }
```
- expiry: `30d`

> Note: refresh-token handling (rotation/revocation) beyond DB insert is not shown in the login code path.

---

## 5. JWT auth middleware (used by other protected endpoints)

File: `neofyn-backend/middleware/authMiddleware.js`

- Expects header:
  - `Authorization: Bearer <token>`
- Verifies token via `jwt.verify(token, process.env.JWT_SECRET)`
- Stores decoded payload into:
  - `req.user`

If missing/invalid token:
- returns `401` with message `No token, authorization denied` or `Token is not valid`.

---

## 6. Database layer

### 6.1 DB connection config: `neofyn-backend/config/db.js`
Uses environment variables:
- `DB_HOST`
- `DB_PORT`
- `DB_USER`
- `DB_PASSWORD`
- `DB_NAME`

### 6.2 Database tables referenced by login flow
The login code references:

1) `users`
- Columns used by code:
  - `id`
  - `first_name`
  - `last_name`
  - `email`
  - `phone`
  - `password` (bcrypt hash)
  - `role` (e.g. `pending`, `rejected`, approved)

2) `refresh_tokens`
- Columns used by code:
  - `user_id`
  - `token`
  - `expires_at`

### 6.3 Additional DB table referenced in token caching endpoint
`routes/authRoutes.js` defines:
- `POST /api/auth/token` that uses:
  - `aeps_tokens`

It reads:
```sql
SELECT token FROM aeps_tokens
WHERE created_at > NOW() - INTERVAL '50 minutes'
ORDER BY created_at DESC
LIMIT 1
```

Then inserts:
- `INSERT INTO aeps_tokens (token) VALUES ($1)`

> This endpoint is NOT called by the Flutter login screen shown in repo, but it is part of the auth router.

---

## 7. Full end-to-end login request sequence

### Step-by-step
1. **Flutter** calls `POST /api/auth/login`
2. **Express** routes to `controllers/authController.login`
3. Backend:
   - validates request body
   - queries `users` by `phone`
   - verifies bcrypt password
   - blocks login if `role` is `pending` or `rejected`
   - generates `accessToken` + `refreshToken`
   - inserts refresh token into `refresh_tokens`
4. Backend returns JSON with token(s) + user summary
5. Flutter stores token in `FlutterSecureStorage` (`jwt_token`) and in `SharedPreferences`
6. Flutter initializes AEPS provider + wallet provider
7. Flutter fetches merchant details by phone
8. Flutter navigates to `UserHomeScreen`

---

## 8. Related files (quick map)

### Flutter
- `my_app/lib/screens/login_screen.dart`

### Backend entry points
- `my_app/neofyn-backend/server.js`
- `my_app/neofyn-backend/routes/authRoutes.js`
- `my_app/neofyn-backend/controllers/authController.js`
- `my_app/neofyn-backend/utils/token.js`
- `my_app/neofyn-backend/middleware/authMiddleware.js`
- `my_app/neofyn-backend/config/db.js`

---

## 9. Known mismatches / implementation notes (based on code)

1) Flutter token parsing is defensive (supports multiple response schemas), but current backend returns:
- `accessToken` and `refreshToken` at top-level.

2) Both `generateAccessToken` and `generateRefreshToken` use the same `JWT_SECRET` env var.

3) Login persists tokens, but backend “refresh” workflow beyond DB insert is not shown.

4) The `/api/auth/token` endpoint caches `aeps_tokens` in DB; it is not the app login token. It’s used for VimoPay/AEPS integration.

---

## Appendix A: Endpoints summary

**Login**
- `POST /api/auth/login`

**Register**
- `POST /api/auth/register`

**Token cache (AEPS)**
- `POST /api/auth/token`

---

End of documentation.

