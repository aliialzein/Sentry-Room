# Users vs Persons

Sentry Room has two different human-related concepts.

## Users

`users` are mobile app accounts. They login or register to use the app.

- Stored in the `users` table.
- Used for app authentication and authorization.
- New registrations default to the `viewer` role.
- A user is not an admin unless their role is explicitly changed to `admin`.
- Roles are `viewer`, `security`, and `admin`.

Main endpoints:

- `POST /api/auth/register`
- `POST /api/auth/login`
- `GET /api/users`
- `PATCH /api/users/{user_id}/role`
- `PATCH /api/users/{user_id}/status`

## Persons

`persons` are people recognized by the camera/face-recognition system.

- Stored in the `persons` table.
- Used by the Raspberry Pi recognition pipeline.
- A person may be authorized or unauthorized for room entry.
- A person does not necessarily have a mobile app login.

Main endpoints:

- `GET /api/persons`
- `POST /api/persons`
- `PATCH /api/persons/{person_id}`
- `POST /api/persons/enroll-from-image`

## Example

An admin user can login to the mobile app and manage recognized persons. The admin user account lives in `users`; the recognized person records live in `persons`.
