const nodemailer = require("nodemailer");

// HTML email template generator
const generateEmailTemplate = (options) => {
  const { subject, message, code } = options;

  // Base template with app colors
  const baseTemplate = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>${subject}</title>
      <style>
        body {
          font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
          margin: 0;
          padding: 0;
          background-color: #f5f5f5;
          color: #333;
        }
        .container {
          max-width: 600px;
          margin: 0 auto;
          padding: 20px;
        }
        .header {
          background-color: #2fa7bb;
          padding: 20px;
          text-align: center;
          border-top-left-radius: 5px;
          border-top-right-radius: 5px;
        }
        .header h1 {
          color: white;
          margin: 0;
          font-size: 24px;
        }
        .content {
          background-color: white;
          padding: 30px;
          border-bottom-left-radius: 5px;
          border-bottom-right-radius: 5px;
          box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
        }
        .verification-code {
          font-size: 32px;
          font-weight: bold;
          text-align: center;
          margin: 30px 0;
          letter-spacing: 5px;
          color: #2fa7bb;
        }
        .message {
          line-height: 1.6;
          margin-bottom: 30px;
        }
        .footer {
          text-align: center;
          margin-top: 30px;
          color: #999;
          font-size: 12px;
        }
        .button {
          display: inline-block;
          background-color: #2fa7bb;
          color: white;
          text-decoration: none;
          padding: 12px 30px;
          border-radius: 4px;
          font-weight: bold;
          margin: 20px 0;
        }
        .logo {
          max-width: 100px;
          margin-bottom: 10px;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>MediLink</h1>
        </div>
        <div class="content">
          ${getEmailContent(options)}
        </div>
        <div class="footer">
          <p>&copy; ${new Date().getFullYear()} MediLink. Tous droits réservés.</p>
          <p>Cet email a été envoyé automatiquement, merci de ne pas y répondre.</p>
        </div>
      </div>
    </body>
    </html>
  `;

  return baseTemplate;
};

// Generate specific content based on email type
const getEmailContent = (options) => {
  const { subject, message, code } = options;

  // If there's a verification code, display it prominently
  if (code) {
    return `
      <h2>Bonjour,</h2>
      <p class="message">
        ${
          subject === "Activation de compte"
            ? "Merci d'avoir créé un compte sur notre plateforme MediLink. Pour finaliser votre inscription, veuillez utiliser le code de vérification ci-dessous."
            : subject === "Mot de passe oublié" ||
              subject === "Changer mot de passe"
            ? "Vous avez demandé la réinitialisation de votre mot de passe. Veuillez utiliser le code de vérification ci-dessous pour continuer."
            : message
        }
      </p>
      <div class="verification-code">${code}</div>
      <p>Ce code est valable pendant 10 minutes.</p>
      <p>Si vous n'êtes pas à l'origine de cette demande, vous pouvez ignorer cet email.</p>
    `;
  }

  // For account activation confirmation
  if (subject === "Compte Activer") {
    return `
      <h2>Félicitations !</h2>
      <p class="message">
        Votre compte MediLink a été activé avec succès. Vous pouvez maintenant vous connecter et profiter de tous nos services.
      </p>
      <div style="text-align: center;">
        <a href="https://medilink-app.com/login" class="button">Se connecter</a>
      </div>
    `;
  }

  // Default content
  return `
    <h2>Bonjour,</h2>
    <p class="message">${message}</p>
  `;
};

const sendEmail = async (options) => {
  try {
    // 1) Create a transporter
    const transport = nodemailer.createTransport({
      service: "gmail",
      host: "smtp.gmail.com",
      port: process.env.PORTMAILER || 587,
      auth: {
        user: process.env.USERMAILER || "",
        pass: process.env.PASSWORDMAILER || "",
      },
    });

    // Generate HTML content
    const htmlContent = generateEmailTemplate({
      subject: options.subject,
      message: options.message,
      code: options.code,
    });

    // 2) Define the email options
    const mailOptions = {
      from: "MediLink <noreply@medilink.com>",
      to: options.email,
      subject: options.subject,
      text: options.message, // Keep plain text version for email clients that don't support HTML
      html: htmlContent,
      attachments: options.attachments,
    };

    // 3) Send the email
    const info = await transport.sendMail(mailOptions);
    console.log(`Email sent: ${info.messageId}`);
    return info;
  } catch (error) {
    console.error("Error sending email:", error);
    throw error; // Rethrow for proper handling in controller
  }
};

module.exports = sendEmail;
