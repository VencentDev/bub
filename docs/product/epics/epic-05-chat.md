# Epic 5: Chat

Chat is the couple's private conversation space.

## US-017 Send Message

As a user, I want to send messages so that I can communicate with my partner.

### Acceptance Criteria

- User can send text.
- User can send emoji.

## US-018 Edit Message

As a user, I want to edit a recent message so that I can correct mistakes.

> Product decision needed: the current Messenger-style long-press action sheet
> excludes Edit. Either restore Edit to the action sheet or mark this story as
> deferred before release.

### Acceptance Criteria

- User can edit a message within 10 minutes.
- User cannot edit a message after the time limit.

## US-019 Delete Message

As a user, I want to delete messages so that I can manage my chat history.

### Acceptance Criteria

- User can delete for me.
- User can delete for everyone.

## US-020 Reply

As a user, I want to reply to a message so that conversation context is preserved.

### Acceptance Criteria

- User can reply to a specific message.
- User can swipe a sent or received message to reply.
- Replied-message previews overlap above the message bubble and preserve context without crowding the replied message.

## US-021 Reactions

As a user, I want to react to messages so that I can respond quickly.

### Acceptance Criteria

- Supported reactions include ❤️, 😂, 🥺, 😭, and 🔥.

## US-022 Typing Indicator

As a user, I want to see when my partner is typing so that chat feels live.

### Acceptance Criteria

- Shows `Typing...`.

## US-023 Read Receipts

As a user, I want message delivery and read state so that I know whether my partner has seen my message.

### Acceptance Criteria

- Shows delivery/read state as checks below the latest outgoing message.
- Does not show receipt text inside the message bubble.
- Does not repeat checks under every message in a continuous outgoing run.
- Hides the latest outgoing receipt once the partner replies.

## US-024 Online Status

As a user, I want online status so that I know whether my partner is available.

### Acceptance Criteria

- Shows Online.
- Shows Offline.
- Shows Last seen.

## US-025 Media Attachments

As a user, I want to send quick images and videos in chat so that I can share moments without leaving the conversation.

### Acceptance Criteria

- User can send one quick image.
- User can send multiple quick images in one action.
- User can send one quick video.
- Multiple quick images display as a gently spread stacked-card message.
- Tapping an image or image stack opens a full-screen viewer with swipe navigation.
- Videos display as separate chat cards.
- Deleted media messages show `This message was deleted` and hide attachments and reactions.
- Replies to media messages preserve context with snippets such as `Photo`, `3 photos`, or `Video`.

## US-026 Attachment Mode Picker

As a user, I want to choose whether an attachment is Safe or Quick so that private saved media and casual chat media have different paths.

### Acceptance Criteria

- Tapping the attachment button first shows Safe and Quick choices.
- Choosing Quick lets the user send images or videos into chat.
- Choosing Safe does not upload media in Epic 5.
- Choosing Safe inserts a divider-style chat row that says `New image added to Safe` or `New video added to Safe` until Epic 7 Safe persistence is implemented.

## US-027 Swipe To Reply

As a user, I want to swipe a message to reply so that replying is fast on mobile.

### Acceptance Criteria

- User can swipe a partner message to reply.
- User can swipe their own message to reply.
- Swipe-to-reply does not block normal vertical chat scrolling.
- Long press actions still work on messages that support swipe-to-reply.

## US No Tether Yet

As a user, I want to see a cute screen and cannot send a message yet when I do not have a tethered account.

### Acceptance Criteria

- Display an empty state screen.
- Display a message in the middle that says something catchy about `Tether someone to start your conversation`.
- Display `tether.png` to cover the whole chat section page as an empty state screen.
