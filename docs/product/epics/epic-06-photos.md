# Epic 6: Photos

Photos can be sent normally in chat or added to the Safe as private memories.

## US-025 Send Normal Photo

As a user, I want to send a normal photo so that it appears inside chat.

### Acceptance Criteria

- Photo appears inside chat.

## US-026 Send Safe Photo

As a user selecting an image, I want to choose whether it is normal or added to Safe so that sensitive memories are stored privately.

### Acceptance Criteria

- Image picker shows Normal option.
- Image picker shows Add to Safe ❤️ option.
- Add to Safe follows Epic 7 Safe PIN protection and stores the media in the shared Safe vault.
- Safe images and videos are not shown as chat thumbnails.

## US-027 Safe Animation

As a user, I want a special Safe animation instead of image previews so that private images stay hidden.

### Acceptance Criteria

- Displays `safe-box.png` instead of the image.
- Shows count text, for example: `5 memories added`.
- Shows View Safe action.
- Uses a cute animation.
- Does not expose Safe media URLs or thumbnails in chat.

## US-028 View Safe Photos

As a user, I want to view Safe photos only after authentication so that private memories stay protected.

### Acceptance Criteria

- Requires the user's Safe PIN for this implementation.
- Password, biometric, fingerprint, and Face ID unlock are deferred to a later security enhancement.

## US-029 Change Safe Password

As a user, I want to change my Safe password method so that access matches my security preference.

### Acceptance Criteria

- User can use PIN in this implementation.
- Biometric and password unlock options are deferred.

## US-030 Download Safe Photo

As a user, I want to download a Safe or quick photo so that I can save it locally.

### Acceptance Criteria

- User can save a Safe photo locally.
