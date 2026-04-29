# Secrets and Credentials Policy

## Rules
- Never commit secrets to git (service account keys, API private keys, access tokens, `.env` files).
- Keep only templates in git (for example: `.env.example`, `serviceAccountKey.example.json`).
- Store runtime secrets locally or in CI secret stores.

## Local Setup
- Admin scripts require `admin_scripts/serviceAccountKey.json` locally.
- This file is intentionally ignored by git.

## Pre-commit Secret Check
- This repo includes a pre-commit hook config using `detect-secrets`.
- Install once:
  - `pip install pre-commit detect-secrets`
  - `pre-commit install`

## Rotation and Incident Response
- If a secret is exposed:
  1. Revoke/rotate immediately in the provider console.
  2. Remove the secret from the repository.
  3. Reissue credentials and update local/CI storage.
