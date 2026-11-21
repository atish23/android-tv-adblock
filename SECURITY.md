# Security Policy

The scripts in this repo install an app on people's TVs, so safety matters.

## Reporting

Please report security problems privately: open the **Security** tab of this repo and choose **Report a vulnerability**. Do not open a public issue for them.

Examples: a script that could install an unverified or changed APK, a command that leaks data, or a rule that sends traffic somewhere unexpected.

You will get a reply as soon as possible, and a fix will be released before the details are made public.

## What we already do

- The installers download personalDNSfilter only from F-Droid and check its SHA-256 before installing. On a mismatch they stop.
- No secrets, accounts or cloud services are used.
