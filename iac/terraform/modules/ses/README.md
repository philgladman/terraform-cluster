# Send email via curl
- Retreive `*-ses-access-key-id` and `*-ses-smtp-password` from AWS SSM Parameter store
- create `email.txt` file below with message contents;
## email.txt
```bash
From: "Name" <sender-email-address>
To: "Name" <destination-email-address>
Subject: This is a test email

Test
```

- run commandbelow
- curl --ssl-reqd smtp://email-smtp.us-east-1.amazonaws.com:587 --mail-from <sender-email-address> --mail-rcpt <destination-email-address> --upload-file ~/email.txt --user '<*-ses-access-key-id>:<*-ses-smtp-password>'

# Send email via openssl
## reference aws docs. https://docs.aws.amazon.com/ses/latest/dg/send-email-smtp-client-command-line.html
- Retreive `*-ses-access-key-id` and `*-ses-smtp-password` from AWS SSM Parameter store
- Base64 ench password and access key id
- `echo -n "*-ses-access-key-id" | openssl enc -base64`
- `echo -n "*-ses-smtp-password" | openssl enc -base64`
- create `email.txt` file below with message contents;

# email.txt
```bash
EHLO example.com
AUTH LOGIN
Base64EncodedSMTPUserName
Base64EncodedSMTPPassword
MAIL FROM: sender@example.com
RCPT TO: recipient@example.com
DATA
X-SES-CONFIGURATION-SET: ConfigSet
From: Sender Name <sender@example.com>
To: recipient@example.com
Subject: Amazon SES SMTP Test

This message was sent using the Amazon SES SMTP interface.
.
QUIT
```
###

# Make the following changes to the email.txt file
- Replace `example.com` with your sending domain.
- Replace `Base64EncodedSMTPUserName` with your base64-encoded SMTP user name.
- Replace `Base64EncodedSMTPPassword` with your base64-encoded SMTP password.
- Replace `sender@example.com` with the email address you are sending from. This identity must be verified.
- Replace `recipient@example.com` with the destination email address. If your Amazon SES account is still in the sandbox, this address must be verified.
- Replace `ConfigSet` with the name of the configuration set that you want to use when you send this email.
- Run command below to send test message
- replace `email-smtp.us-east-1.amazonaws.com` with the applicable ses region endpoint.

`openssl s_client -crlf -quiet -starttls smtp -connect email-smtp.us-east-1.amazonaws.com:587 < email.txt`
