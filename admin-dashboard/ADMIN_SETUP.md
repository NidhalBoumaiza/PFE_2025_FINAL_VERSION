# Admin Account Setup Guide

This guide will help you create admin accounts for your medical app
admin dashboard.

## Quick Start

### Option 1: Use the Batch File (Windows)

Double-click `scripts/create_admin.bat` or run:

```cmd
scripts\create_admin.bat
```

### Option 2: Use the Shell Script (Linux/Mac)

```bash
./scripts/create_admin.sh
```

### Option 3: Run Directly with Dart

```bash
dart run scripts/create_admin.dart
```

## What You'll Need

1. **Email address** for the admin account
2. **Password** (minimum 6 characters)
3. **Name** for the admin (optional, defaults to "Admin")
4. **Phone number** (optional)

## Example Session

```
🚀 Starting Admin Account Creation Script...

✅ Firebase initialized successfully

📝 Please provide admin account details:
Enter admin email: admin@yourcompany.com
Enter admin password (minimum 6 characters): securepassword123
Enter admin name (default: Admin): System Administrator
Enter admin phone number (optional): +1234567890

🔄 Creating admin account...
✅ Firebase Auth user created successfully
✅ User document created in Firestore

🎉 Admin account created successfully!
📧 Email: admin@yourcompany.com
👤 Name: System Administrator
🔑 Role: admin
🆔 User ID: xyz789abc123

✨ You can now log in to the admin dashboard with these credentials.
```

## After Creating an Admin Account

1. **Test the login**: Open your admin dashboard and log in with the
   created credentials
2. **Verify permissions**: Ensure all admin features are accessible
3. **Create additional admins**: Run the script again to create more
   admin accounts if needed

## Troubleshooting

### Common Issues

1. **"Firebase connection error"**

   - Check your internet connection
   - Verify Firebase project is accessible
   - Ensure Authentication and Firestore are enabled in Firebase
     Console

2. **"Email already in use"**

   - The script will automatically handle this by updating the
     existing user to admin role
   - If you want a different email, use a new email address

3. **"Permission denied"**

   - Make sure your Firebase project has proper permissions
   - Check that Authentication and Firestore are enabled

4. **"Dart not found"**
   - Install Dart SDK from https://dart.dev/get-dart
   - Make sure Dart is in your system PATH

### Getting Help

If you encounter issues:

1. Check the detailed README in `scripts/README.md`
2. Verify your Firebase project configuration
3. Ensure all dependencies are installed with `dart pub get`

## Security Best Practices

- Use strong passwords for admin accounts
- Don't share admin credentials
- Regularly review admin account access
- Consider using email addresses that are monitored by your team

## Files Created

This setup includes:

- `scripts/create_admin.dart` - Main script
- `scripts/pubspec.yaml` - Dependencies
- `scripts/README.md` - Detailed documentation
- `scripts/create_admin.bat` - Windows batch file
- `scripts/create_admin.sh` - Unix/Linux shell script
