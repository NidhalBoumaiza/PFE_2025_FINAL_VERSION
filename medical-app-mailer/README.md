# Medical App Mailer

This is the backend service for the Medical App project.

## Dossier Medical API

The Dossier Medical API allows you to manage patient medical files.

### Endpoints

#### Get a Patient's Medical Record

```
GET /api/v1/dossier-medical/:patientId
```

**Response**

```json
{
  "status": "success",
  "data": {
    "dossier": {
      "_id": "60d21b4667d0d8992e610c85",
      "patientId": "firebase-patient-id",
      "files": [
        {
          "_id": "60d21b4667d0d8992e610c86",
          "filename": "2023-06-20T10-30-45.123Z-blood-test.pdf",
          "originalName": "blood-test.pdf",
          "path": "uploads/patient-files/firebase-patient-id/2023-06-20T10-30-45.123Z-blood-test.pdf",
          "mimetype": "application/pdf",
          "size": 123456,
          "description": "Blood test results from May 2023",
          "createdAt": "2023-06-20T10:30:45.123Z"
        }
      ],
      "createdAt": "2023-06-20T10:30:45.123Z",
      "updatedAt": "2023-06-20T10:30:45.123Z"
    }
  }
}
```

#### Add a Single File to a Patient's Medical Record

```
POST /api/v1/dossier-medical/:patientId/files
```

**Request**

- Format: `multipart/form-data`
- Fields:
  - `file`: The file to upload (required)
  - `description`: Description of the file (optional)

**Response**

```json
{
  "status": "success",
  "data": {
    "dossier": {
      "_id": "60d21b4667d0d8992e610c85",
      "patientId": "firebase-patient-id",
      "files": [
        {
          "_id": "60d21b4667d0d8992e610c86",
          "filename": "2023-06-20T10-30-45.123Z-blood-test.pdf",
          "originalName": "blood-test.pdf",
          "path": "uploads/patient-files/firebase-patient-id/2023-06-20T10-30-45.123Z-blood-test.pdf",
          "mimetype": "application/pdf",
          "size": 123456,
          "description": "Blood test results from May 2023",
          "createdAt": "2023-06-20T10:30:45.123Z"
        }
      ],
      "createdAt": "2023-06-20T10:30:45.123Z",
      "updatedAt": "2023-06-20T10:30:45.123Z"
    }
  }
}
```

#### Add Multiple Files to a Patient's Medical Record

```
POST /api/v1/dossier-medical/:patientId/multiple-files
```

**Request**

- Format: `multipart/form-data`
- Fields:
  - `files`: The files to upload (required, up to 10 files)
  - `descriptions`: JSON object mapping file IDs to descriptions
    (optional) Example:
    `{"file1": "X-ray report", "file2": "MRI scan"}`

**Response**

```json
{
  "status": "success",
  "data": {
    "dossier": {
      "_id": "60d21b4667d0d8992e610c85",
      "patientId": "firebase-patient-id",
      "files": [
        {
          "_id": "60d21b4667d0d8992e610c86",
          "filename": "2023-06-20T10-30-45.123Z-blood-test.pdf",
          "originalName": "blood-test.pdf",
          "path": "uploads/patient-files/firebase-patient-id/2023-06-20T10-30-45.123Z-blood-test.pdf",
          "mimetype": "application/pdf",
          "size": 123456,
          "description": "Blood test results from May 2023",
          "createdAt": "2023-06-20T10:30:45.123Z"
        },
        {
          "_id": "60d21b4667d0d8992e610c87",
          "filename": "2023-06-20T10-31-45.123Z-xray.jpg",
          "originalName": "xray.jpg",
          "path": "uploads/patient-files/firebase-patient-id/2023-06-20T10-31-45.123Z-xray.jpg",
          "mimetype": "image/jpeg",
          "size": 234567,
          "description": "Chest X-ray from June 2023",
          "createdAt": "2023-06-20T10:31:45.123Z"
        }
      ],
      "createdAt": "2023-06-20T10:30:45.123Z",
      "updatedAt": "2023-06-20T10:31:45.123Z"
    }
  }
}
```

#### Update a File Description

```
PATCH /api/v1/dossier-medical/:patientId/files/:fileId
```

**Request**

```json
{
  "description": "Updated description for the file"
}
```

**Response**

```json
{
  "status": "success",
  "data": {
    "file": {
      "_id": "60d21b4667d0d8992e610c86",
      "filename": "2023-06-20T10-30-45.123Z-blood-test.pdf",
      "originalName": "blood-test.pdf",
      "path": "uploads/patient-files/firebase-patient-id/2023-06-20T10-30-45.123Z-blood-test.pdf",
      "mimetype": "application/pdf",
      "size": 123456,
      "description": "Updated description for the file",
      "createdAt": "2023-06-20T10:30:45.123Z"
    }
  }
}
```

#### Delete a File

```
DELETE /api/v1/dossier-medical/:patientId/files/:fileId
```

**Response**

```json
{
  "status": "success",
  "message": "Fichier supprimé avec succès"
}
```

### File Access

Files can be accessed directly via their URL:

```
GET /uploads/patient-files/:patientId/:filename
```

### Supported File Types

- Images: JPEG, PNG, JPG
- Documents: PDF

### File Size Limit

Maximum file size: 10MB per file

## Authentication

All endpoints require authentication. Include the JWT token in the
Authorization header:

```
Authorization: Bearer your-token-here
```
