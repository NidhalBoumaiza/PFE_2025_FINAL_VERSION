# Medical App Mailer

This is a simplified backend service focused on email functionality and password reset for the Medical App project.

## Features

- **Email Service**: Send various types of emails (account activation, password reset, etc.)
- **Password Reset**: Direct password reset functionality using Firebase Authentication
- **Beautiful Email Templates**: HTML email templates with modern design
- **Rate Limiting**: Protection against spam and abuse
- **CORS Support**: Cross-origin resource sharing enabled
- **XSS Protection**: Built-in security against cross-site scripting

## API Endpoints

### Email Service

#### Send Email

```
POST /api/v1/users/sendMailService
```

**Request Body**

```json
{
  "email": "user@example.com",
  "subject": "Activation de compte", // or "Mot de passe oublié", "Changer mot de passe", "Compte Activer"
  "code": "123456" // Optional, required for verification emails
}
```

**Supported Email Types**

- `"Activation de compte"` - Account activation with verification code
- `"Mot de passe oublié"` - Forgot password with reset code
- `"Changer mot de passe"` - Change password with verification code
- `"Compte Activer"` - Account activation confirmation (no code needed)

**Response**

```json
{
  "status": "success",
  "message": "Un e-mail a été envoyé à user@example.com avec succès"
}
```

### Password Reset

#### Reset Password Directly

```
POST /api/v1/users/resetPasswordDirect
```

**Request Body**

```json
{
  "email": "user@example.com",
  "newPassword": "newSecurePassword123",
  "verificationCode": "123456"
}
```

**Response**

```json
{
  "status": "success",
  "message": "Mot de passe réinitialisé avec succès"
}
```

## Environment Variables

Create a `.env` file in the root directory with the following variables:

```env
# Email Configuration
USERMAILER=your-gmail-address@gmail.com
PASSWORDMAILER=your-app-password
PORTMAILER=587

# Firebase Configuration
# Place your serviceAccountKey.json file in the root directory

# Application Configuration
NODE_ENV=development
PORT=3000
```

## Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   npm install
   ```
3. Set up environment variables (see above)
4. Place your Firebase service account key file as `serviceAccountKey.json` in the root directory
5. Start the server:
   ```bash
   npm start
   ```

## Dependencies

- **express**: Web framework
- **nodemailer**: Email sending functionality
- **firebase-admin**: Firebase authentication and Firestore
- **cors**: Cross-origin resource sharing
- **express-rate-limit**: Rate limiting middleware
- **xss-clean**: XSS protection
- **morgan**: HTTP request logger

## Email Templates

The service includes beautiful HTML email templates with:
- Modern, responsive design
- App branding (MediLink)
- Prominent verification code display
- Professional styling
- Mobile-friendly layout

## Security Features

- Rate limiting (1,000,000 requests per hour per IP)
- XSS protection
- CORS enabled
- Input validation
- Firebase authentication integration

## Development

For development mode, authentication is disabled to make testing easier. In production, proper authentication middleware is applied.

```bash
# Development mode
npm start

# Production mode
NODE_ENV=production npm run dev
```

## Error Handling

The API includes comprehensive error handling with appropriate HTTP status codes and descriptive error messages in French.

## Firebase Integration

The service integrates with Firebase for:
- User authentication and password management
- Firestore database for user verification codes
- Support for multiple user collections (patients, medecins, users)
