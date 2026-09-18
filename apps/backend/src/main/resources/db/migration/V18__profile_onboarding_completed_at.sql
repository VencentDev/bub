ALTER TABLE users
  ADD COLUMN profile_onboarding_completed_at TIMESTAMPTZ;

-- Existing accounts should not be forced through the new profile stepper.
UPDATE users
SET profile_onboarding_completed_at = COALESCE(terms_accepted_at, created_at, NOW())
WHERE profile_onboarding_completed_at IS NULL;
