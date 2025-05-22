const catchAsync = require("../utils/catchAsync");
const AppError = require("../utils/appError");
const sendEmail = require("../utils/email");
const admin = require("firebase-admin");
//-----------------------------------------

//-----------------------------------------

//----------- Sign Up ---------------------

exports.sendMailService = catchAsync(async (req, res, next) => {
  if (!req.body.email || !req.body.subject) {
    return next(
      new AppError(
        "Veuillez saisir votre adresse e-mail et Sujet de l'email",
        400
      )
    );
  }
  if (req.body.subject != "Compte Activer" && !req.body.code) {
    return next(new AppError("Veuillez saisir un code", 400));
  }
  subject = req.body.subject;
  let message = "";
  let code = req.body.code;
  if (subject === "Compte Activer") {
    message = `Bonjour,\n
      Merci de créer un compte a notre platform.\n
      Vore Compte est maintenant activer !`;
  } else if (subject === "Activation de compte") {
    message = `Bonjour,\n
      Merci de créer un compte a notre platform.\n
      Voici le code d'activation de votre compte : ${code}.\n
      Veuillez le saisir pour activer votre compte.`;
  } else if (subject === "Mot de passe oublié") {
    message = `Bonjour,\n
      Merci de créer un compte a notre platform.\n
      Voici le code de réinitialisation de votre mot de passe : ${code.toString}.\n
      Veuillez le saisir pour réinitialiser votre mot de passe.`;
  } else if (subject === "Changer mot de passe") {
    message = `Bonjour,\n
      Voici le code de réinitialisation de votre mot de passe : ${code.toString}.\n
      Veuillez le saisir pour réinitialiser votre mot de passe.`;
  }

  try {
    await sendEmail({
      email: req.body.email,
      subject: req.body.subject || "Activation de compte",
      message,
      code: req.body.code,
    });
    res.status(201).json({
      status: "success",
      message: `Un e-mail a été envoyé à ${req.body.email} avec succès`,
    });
  } catch (err) {
    console.log(err);
    return next(
      new AppError(
        "Une erreur s'est produite lors de l'envoi de l'e-mail ! Merci d'essayer plus tard .",
        500
      )
    );
  }
});

// Direct password reset using Firebase Admin
exports.resetPasswordDirect = catchAsync(async (req, res, next) => {
  const { email, newPassword, verificationCode } = req.body;

  if (!email || !newPassword || !verificationCode) {
    return next(
      new AppError(
        "L'email, le nouveau mot de passe et le code de vérification sont requis",
        400
      )
    );
  }

  try {
    console.log(`Password reset request for email: ${email}`);

    // 1. Verify the verification code in Firestore
    const normalizedEmail = email.toLowerCase().trim();
    const collections = ["patients", "medecins", "users"];

    let userData = null;
    let collectionName = null;
    let userId = null;

    // Search for the user in all collections
    for (const collection of collections) {
      console.log(
        `Searching in ${collection} collection for email: ${normalizedEmail}`
      );

      const snapshot = await admin
        .firestore()
        .collection(collection)
        .where("email", "==", normalizedEmail)
        .get();

      if (!snapshot.empty) {
        collectionName = collection;
        userId = snapshot.docs[0].id;
        userData = snapshot.docs[0].data();
        console.log(`User found in ${collection} with ID: ${userId}`);
        break;
      }
    }

    if (!userData) {
      console.log(`User not found for email: ${normalizedEmail}`);
      return next(new AppError("Utilisateur non trouvé", 404));
    }

    // 2. Verify the code
    if (userData.verificationCode !== verificationCode) {
      console.log(
        `Invalid verification code. Expected: ${userData.verificationCode}, Received: ${verificationCode}`
      );
      return next(new AppError("Code de vérification invalide", 400));
    }

    // 3. Check if code is expired
    const validationExpiry =
      userData.validationCodeExpiresAt?.toDate();
    if (!validationExpiry || validationExpiry < new Date()) {
      console.log(
        `Verification code expired. Expiry: ${validationExpiry}, Current: ${new Date()}`
      );
      return next(
        new AppError("Le code de vérification a expiré", 400)
      );
    }

    // 4. Check code type
    const codeType = userData.codeType;
    if (
      codeType !== "motDePasseOublie" &&
      codeType !== "changerMotDePasse"
    ) {
      console.log(`Invalid code type: ${codeType}`);
      return next(
        new AppError(
          "Type de code invalide pour la réinitialisation du mot de passe",
          400
        )
      );
    }

    // 5. Update the password using Firebase Auth Admin
    try {
      console.log(
        `Resetting password for user with email: ${normalizedEmail}`
      );

      // Get user by email and update password
      const userRecord = await admin
        .auth()
        .getUserByEmail(normalizedEmail);
      await admin.auth().updateUser(userRecord.uid, {
        password: newPassword,
      });

      console.log(
        `Password successfully reset for user: ${userRecord.uid}`
      );

      // 6. Clear verification code in Firestore
      await admin
        .firestore()
        .collection(collectionName)
        .doc(userId)
        .update({
          verificationCode: null,
          validationCodeExpiresAt: null,
          codeType: null,
        });

      console.log(`Verification code cleared for user: ${userId}`);

      // 7. Return success response
      res.status(200).json({
        status: "success",
        message: "Mot de passe réinitialisé avec succès",
      });
    } catch (error) {
      console.error(`Error updating password: ${error.message}`);
      return next(
        new AppError(
          `Erreur lors de la réinitialisation du mot de passe: ${error.message}`,
          500
        )
      );
    }
  } catch (error) {
    console.error(`Unexpected error: ${error.message}`);
    return next(
      new AppError("Une erreur inattendue s'est produite", 500)
    );
  }
});

// Authentication middleware
exports.protect = catchAsync(async (req, res, next) => {
  let token;

  // 1) Get token from Authorization header
  if (
    req.headers.authorization &&
    req.headers.authorization.startsWith("Bearer")
  ) {
    token = req.headers.authorization.split(" ")[1];
  }

  // 2) Check if token exists
  if (!token) {
    // For development/testing purposes, proceed without authentication
    console.log(
      "No authentication token provided, proceeding without authentication"
    );
    return next();

    // In production, you would return an error:
    // return next(new AppError('Vous n\'êtes pas connecté. Veuillez vous connecter pour accéder.', 401));
  }

  try {
    // 3) Verify token (this is a simplified version)
    // In a real implementation, you would verify the JWT token with Firebase
    // const decodedToken = await admin.auth().verifyIdToken(token);
    // req.user = { id: decodedToken.uid, email: decodedToken.email };

    console.log(
      "Token received but not verified in development mode"
    );
    return next();
  } catch (error) {
    console.error("Error verifying authentication token:", error);
    // For development/testing purposes, proceed without authentication
    return next();

    // In production, you would return an error:
    // return next(new AppError('Token invalide ou expiré. Veuillez vous reconnecter.', 401));
  }
});
