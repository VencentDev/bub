# Epic 2: Tether Pairing

Tether is Bub's primary feature: one account, one tether, forever until removed.

## Product Rules

- A user account can only have one active tether.
- A tether connects exactly two user accounts.
- A user cannot tether to themselves.
- Removing a tether is destructive for shared couple data.

## US-004 Receive Tether Code

After login, I want to enter my partner's tether code so that we become paired.

### Acceptance Criteria

- User can enter a tether code.
- System validates the code.
- User cannot tether to themselves.
- Code expires.
- Code is one-time use.

## US-005 Generate Tether Code

As a user, I want to generate a tether invitation so that I can invite my partner.

### Acceptance Criteria

- User can generate a code in the format `BUB-7KQ2-XH19`.
- User can share the invitation using a QR code.
- User can copy the invitation code.

## US-006 Skip Pairing

As a new user, I want to skip pairing so that I can explore Bub first.

### Acceptance Criteria

- Home displays: `You're not tethered yet ❤️`

## US-007 Accept Invitation

As a user, I want to accept a tether invite so that our accounts become permanently connected.

### Acceptance Criteria

- Both users receive confirmation.
- Both home screens update instantly.

## US-008 Remove Tether

As a user, I want to untether so that I can pair with someone else.

### Acceptance Criteria

- User must confirm removal.
- Removing a tether removes Shared Moments.
- Removing a tether removes Bub History.
- Removing a tether removes Shared Safe.
- Removing a tether removes Chat History.
