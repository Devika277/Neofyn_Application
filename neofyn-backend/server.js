require('dotenv').config();
const express = require('express');
const cors = require('cors');
const authRoutes = require('./routes/authRoutes');
const dmtRoutes = require('./routes/dmtRoute');
const masterRoutes = require('./routes/master');
const merchantRoutes = require('./routes/merchant');
const app = express();

app.use(express.json());
app.use(express.urlencoded({ extended: true }));  // Parses URL-encoded bodies

console.log("JWT_SECRET loaded:", process.env.JWT_SECRET ? "YES" : "MISSING ❌");


app.use(cors());
app.use(express.urlencoded({ extended: true }));



app.use('/api/master', masterRoutes);
app.use('/api/merchant', merchantRoutes);


// Routes [cite: 175]
app.use('/api/auth', authRoutes);
app.use('/dmt', dmtRoutes);
app.get('/', (req, res) => res.json({ status: "Server Health: OK" }));
app.use('/api/recharge', require('./routes/rechargeRoutes'));
app.use('/api/bbps', require('./routes/bbpsRoutes'));


const PORT = process.env.PORT || 5000;
app.listen(PORT, '0.0.0.0', () => console.log(` Neofyn Backend runnind and currectly fetching ${PORT} and accessible on all interfaces`));