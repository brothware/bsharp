# Task 004: Poczta Endpoints

## Status: Done

## Description
Define the Poczta (mail) endpoints: SSO login, inbox, sent, trash, read message, search receivers, send message, star, delete, restore.

## Acceptance Criteria
- [x] GET /sso/{school}/{token} returns 302 redirect
- [x] GET / returns HTML with csrfToken embedded
- [x] POST /api/messages/inbox returns message list with author, date, subject, content, read_at, stared, recipients
- [x] POST /api/messages/sent and trash return similar lists
- [x] GET /api/messages/read/{id} returns full message
- [x] POST /api/messages/receivers returns receiver types
- [x] POST /api/messages/receivers/search returns receiver list
- [x] PUT /api/messages accepts send payload
- [x] DELETE /api/messages/{id}, POST star/restore endpoints defined
- [x] 401 error responses for unauthenticated access (SSO, inbox, sent, send)

