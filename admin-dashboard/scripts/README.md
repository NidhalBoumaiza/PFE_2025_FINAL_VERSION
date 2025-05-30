# Admin Account Creation Script

This script allows you to create admin accounts for your medical app
admin dashboard.

## Prerequisites

1. Make sure you have Dart SDK installed
2. Ensure you have access to the Firebase project
3. Make sure your Firebase project has Authentication and Firestore
   enabled

## How to Use

### Method 1: Run from the scripts directory

1. Navigate to the scripts directory:

   ```bash
   cd scripts
   ```

2. Install dependencies:

   ```bash
   dart pub get
   ```

3. Run the script:
   ```bash
   dart run create_admin.dart
   ```

### Method 2: Run from the main project directory

You can also run the script directly from your main project directory
since it uses the same Firebase dependencies:

```bash
dart run scripts/create_admin.dart
```

## What the Script Does

1. **Initializes Firebase** with your project configuration
2. **Prompts for admin details**:

   - Email address (required)
   - Password (minimum 6 characters, required)
   - Name (optional, defaults to "Admin")
   - Phone number (optional)

3. **Creates the admin account**:

   - Creates a user in Firebase Authentication
   - Creates a user document in Firestore with admin role
   - Handles existing email scenarios gracefully

4. **Provides confirmation** with the created account details

## Example Usage

```
🚀 Starting Admin Account Creation Script...

✅ Firebase initialized successfully

📝 Please provide admin account details:
Enter admin email: admin@example.com
Enter admin password (minimum 6 characters): admin123
Enter admin name (default: Admin): John Admin
Enter admin phone number (optional): +1234567890

🔄 Creating admin account...
✅ Firebase Auth user created successfully
✅ User document created in Firestore

🎉 Admin account created successfully!
📧 Email: admin@example.com
👤 Name: John Admin
🔑 Role: admin
🆔 User ID: abc123xyz789

✨ You can now log in to the admin dashboard with these credentials.
```

## Error Handling

The script includes comprehensive error handling for:

- Invalid email addresses
- Passwords that are too short
- Existing email addresses (will attempt to update the existing user)
- Firebase connection issues
- Firestore write failures

## Security Notes

- The script will automatically sign out after creating the account
- If Firestore write fails, it will attempt to clean up the Firebase
  Auth user
- Passwords are handled securely through stdin
- The script uses your existing Firebase configuration

## Troubleshooting

If you encounter issues:

1. **Firebase connection errors**: Ensure your internet connection is
   stable and Firebase project is accessible
2. **Permission errors**: Make sure your Firebase project has
   Authentication and Firestore enabled
3. **Dependency errors**: Run `dart pub get` in the scripts directory
4. **Email already exists**: The script will handle this automatically
   by updating the existing user's role to admin

## Next Steps

After creating an admin account:

1. Test login in your admin dashboard
2. The account will have full admin privileges
3. You can create additional admin accounts by running the script
   again
