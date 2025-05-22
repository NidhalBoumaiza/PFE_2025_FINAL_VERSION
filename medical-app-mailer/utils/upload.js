const multer = require("multer");
const path = require("path");
const fs = require("fs");
const AppError = require("./appError");

// Ensure the upload directories exist
const ensureDirectoryExists = (dirPath) => {
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
    console.log(`Created directory: ${dirPath}`);
  }
};

// Create base directories
const baseUploadDir = path.join(__dirname, "../uploads");
const patientFilesDir = path.join(baseUploadDir, "patient-files");

ensureDirectoryExists(baseUploadDir);
ensureDirectoryExists(patientFilesDir);

// Storage configuration for patient medical files
const medicalFilesStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    // Create a directory for each patient based on their ID
    const patientId = req.params.patientId || req.body.patientId;
    if (!patientId) {
      return cb(new AppError("L'ID du patient est requis", 400));
    }

    const patientDir = path.join(patientFilesDir, patientId);
    ensureDirectoryExists(patientDir);
    cb(null, patientDir);
  },
  filename: (req, file, cb) => {
    // Create a unique filename with timestamp
    const timestamp = new Date().toISOString().replace(/:/g, "-");
    const originalNameParts = file.originalname.split(".");
    const originalName = originalNameParts.slice(0, -1).join(".");
    const ext = originalNameParts[originalNameParts.length - 1];

    cb(null, `${timestamp}-${originalName}.${ext}`);
  },
});

// File filter to accept only images and PDF files
const medicalFilesFilter = (req, file, cb) => {
  const allowedFileTypes = [
    "image/jpeg",
    "image/png",
    "image/jpg",
    "application/pdf",
  ];

  if (allowedFileTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(
      new AppError(
        "Type de fichier non supporté. Veuillez télécharger une image (JPEG, PNG) ou un document PDF.",
        400
      ),
      false
    );
  }
};

// Create the multer upload instances
const medicalFileUpload = multer({
  storage: medicalFilesStorage,
  fileFilter: medicalFilesFilter,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB max file size
  },
});

// Export the upload functions
exports.uploadSingleMedicalFile = medicalFileUpload.single("file");
exports.uploadMultipleMedicalFiles = medicalFileUpload.array(
  "files",
  10
); // Allow up to 10 files at once
