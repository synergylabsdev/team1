# Supabase Email Confirmation Setup

## Disable Email Confirmation (Auto-Confirm Users)

To disable email OTP/confirmation and enable auto-confirmation:

1. Go to your Supabase Dashboard: https://supabase.com/dashboard
2. Select your project
3. Navigate to **Authentication** → **Settings** (or **Auth** → **Configuration**)
4. Find the **Email Auth** section
5. **Disable** the following options:
   - ✅ **"Enable email confirmations"** - Turn this OFF
   - ✅ **"Enable email change confirmations"** - Turn this OFF (optional)
   - ✅ **"Enable secure email change"** - Turn this OFF (optional)

6. Save the changes

## Alternative: Using SQL (if available)

You can also run this SQL in the Supabase SQL Editor:

```sql
-- Disable email confirmation requirement
UPDATE auth.config 
SET enable_signup = true,
    enable_email_confirmations = false;
```

## What This Does

- Users will be **automatically confirmed** upon signup
- No email verification required
- Users can login immediately after signup
- Session is created immediately after signup

## Security Note

⚠️ **Warning**: Disabling email confirmation reduces security. Only do this for:
- Development/testing environments
- Internal applications
- Applications with alternative verification methods

For production apps, consider keeping email confirmation enabled for better security.

