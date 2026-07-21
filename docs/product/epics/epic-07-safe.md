# Epic 7: Safe

Safe is Bub's private vault for intimate memories.

## US-031 Unlock Safe

As a user, I want to unlock Safe securely so that private memories are protected.

### Acceptance Criteria

- If no Safe PIN exists, user can create a 4 to 6 digit PIN.
- If a Safe PIN exists, user must enter the correct PIN before viewing, adding, or deleting Safe media.
- PIN entry is required for the current app session before Safe contents are shown.
- PIN is the implemented unlock method; biometric and password unlock are deferred.

## US-032 Organize Safe

As a user, I want to organize Safe memories so that I can browse them later.

### Acceptance Criteria

- Safe supports images and videos added by either tethered partner.
- Safe gallery is sorted by recent, newest first.
- Deleted media is excluded from the gallery.

## US-033 Delete Safe Photo

As a user, I want to delete a Safe photo so that I can remove private memories when needed.

### Acceptance Criteria

- Confirmation is required before deletion.
- Either tethered partner can delete an item from the shared Safe vault after PIN verification.
- Deleted Safe media is removed from the gallery.

## US-034 Notification

As a user, I want to see a notification in the messages to notify that someone added into the vault.

### Acceptance Criteria

- Chat displays `safe-box.png` as the Safe notice visual instead of a pill placeholder.
- Chat indicates how many files were added to Safe.
- Chat does not display Safe thumbnails or Safe media URLs.
