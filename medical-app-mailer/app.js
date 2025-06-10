const cors = require("cors");
const express = require("express");
const morgan = require("morgan");
const rateLimit = require("express-rate-limit");
const AppError = require("./utils/appError");
const globalErrorHandler = require("./controllers/errorController");
const xss = require("xss-clean");
const app = express();

//------------ROUTES----------------
const userRouter = require("./routes/userRouter");

//------------------------------
// Implement CORS
app.use(cors());
app.use(xss());
app.use(morgan("dev"));

// Body parser, reading data from body into req.body
app.use(express.json({ limit: "10kb" }));
app.use(express.urlencoded({ extended: true, limit: "10kb" }));

// 1) GLOBAL MIDDLEWARES
const limiter = rateLimit({
  max: 1000000,
  windowMs: 60 * 60 * 1000,
  message:
    "Too many requests from this IP, please try again in an hour!",
});
app.use("/api", limiter);

// Development logging
if (process.env.NODE_ENV === "development") {
  app.use(morgan("dev"));
}

// Request time middleware
app.use((req, res, next) => {
  req.requestTime = new Date().toISOString();
  next();
});

// 3) ROUTES
app.use("/api/v1/users", userRouter);

// Handle undefined routes
app.all("*", (req, res, next) => {
  next(
    new AppError(`Can't find ${req.originalUrl} on this server!`, 404)
  );
});

// Global error handler
app.use(globalErrorHandler);

module.exports = app;
