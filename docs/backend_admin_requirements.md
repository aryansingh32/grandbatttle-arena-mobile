# Grand Battle Arena – Backend & Admin Requirements (Spring Boot)

This note summarizes the server-side work required so the Flutter client can run 100% dynamically (tournaments, filters, banners, prizes, slots, etc.). The backend stack is Spring Boot, and the admin panel should expose matching controls.

---

## 1. Authentication & User Metadata
1. **Expose team/player info for Flutter**  
   - Endpoint `GET /api/users/me` already exists; ensure it returns:
     - `firebaseUserUID`, `userName`, `email`, `role`, `status`, `createdAt`
     - Optional: `avatarUrl`, `linkedDiscord`, etc. for richer profile views.
2. **Version / forced update endpoint**  
   - Provide `GET /api/app/version` returning `{ "minSupported": "1.1.0", "latest": "1.3.2", "playStoreUrl": "..." }`.
   - Flutter uses this during startup + profile “Check for updates.”
3. **Notification token registration**  
   - Endpoint `POST /api/users/device-token` should accept `{ "deviceToken": "fcm..." }` and store it per user for pushes.

---

## 2. Tournaments API
### Required fields for every tournament payload
- `id`, `title`, `game`, `imageLink`, `map`, `entryFee`, `prizePool`, `maxPlayers`
- **Team size field (MUST be non-null)**: supply one of:
  - `teamSize` (preferred)
  - `team_type`, `teamType`, or `team_size` (fallback).  
  Accepted values: `SOLO`, `DUO`, `SQUAD`, `HEXA`, or their numeric equivalents (1/2/4/6). Flutter defaults to “Solo” if value is missing.
- `status` (`UPCOMING`, `LIVE`, `COMPLETED`) to drive filters.
- `startTime` (ISO8601) for countdowns and schedule filters.
- `rules`: `List<String>` describing format.
- `participants`: `[{ "playerName": "...", "slotNumber": 8, "userId": "..." }]`
- **Scoreboard data** (new): `scoreboard: [{ playerName, teamName, kills, coinsEarned, placement }]`
- **Prize detail fields** (new):
  - `perKillReward` (coins per kill)
  - `firstPrize`, `secondPrize`, `thirdPrize` (coins or Rs.)

### Endpoints in use
1. `GET /api/public/tournaments` – Home list (public).  
   - Needs `teamSize`, `imageLink`, etc.
2. `GET /api/tournaments` – Authenticated list (filters tab).  
   - Same fields as above plus admin-only metadata if necessary.
3. `GET /api/public/tournaments/{id}` – Details shown before login (optional).  
4. `GET /api/tournaments/{id}` – Used by detail + registration screens.
5. `GET /api/slots/{tournamentId}/summary` – Must return `{ slots: [...] }`
   - Each slot object: `{ id, slotNumber, status, firebaseUserUID, playerName, booked_at }`
   - If no slots exist, return an empty array instead of `null`.
6. `POST /api/slots/book-team` – Body: `{ tournamentId, players: [{ slotNumber, playerName }] }`

### Filters metadata
- Provide `GET /api/filters` returning:
  ```json
  {
    "games": ["Free Fire", "PUBG", "COD Mobile"],
    "teamSizes": ["Solo", "Duo", "Squad"],
    "maps": ["Bermuda", "Purgatory"],
    "timeSlots": ["6:00-6:30 PM", "7:00-8:00 PM"]
  }
  ```
  Flutter can cache this for quick filter chips on Home/Tournaments.

---

## 3. Slot Management & Real-Time Updates
1. **Slot summary response always needs `slots` array**  
   - Return `[]` instead of `null` when no slots exist.
   - Include `status` values such as `AVAILABLE`, `BOOKED`, `PENDING`.
2. **Optional: push updates via WebSocket/SSE**  
   - Current design polls every second; server-side push would reduce load.
3. **Team validation**  
   - Backend should reject bookings unless `players.length == playersPerTeam` (or `>=` for multi-slot booking). Flutter enforces this, but backend must validate.

---

## 4. Dynamic Banners & Admin Ads
1. Endpoint `GET /api/banners` should return active banner entries:
   ```json
   [{
     "id": 1,
     "imageUrl": "https://cdn.example.com/banner1.jpg",
     "title": "Free Fire Tournament",
     "description": "Win big prizes!",
     "actionUrl": "https://youtube.com/...",
     "type": "image",       // or "video"/"ad"
     "order": 1,
     "isActive": true,
     "startDate": "2025-11-01T00:00:00Z",
     "endDate": "2025-11-30T00:00:00Z"
   }]
   ```
2. Admin panel should allow:
   - Uploading banner images (or linking external URLs).
   - Setting start/end time, priority/order, CTA link.
   - Enabling/disabling banners.

---

## 5. Admin Panel UX
To support all dynamic client features, add the following admin views:
1. **Tournament editor**
   - CRUD for tournaments with fields mentioned above.
   - Multi-tab interface for details, prize structure (per-kill, podium prizes), participants, scorecard entries.
2. **Slot monitor**
   - Visual grid showing each tournament’s slots, with controls to release/book manually.
3. **Banner manager**
   - List of banners with preview, status toggle, schedule.
4. **Filter metadata editor**
   - Manage game list, maps, team sizes, and time slots so the client can render chips dynamically.
5. **Version management**
   - Input for `minSupportedVersion`, `latestVersion`, and `storeUrl`.
6. **Notification dashboard**
   - List of registered device tokens (from `/api/users/device-token`) and ability to trigger campaign pushes (optional but helpful for testing).

---

## 6. Miscellaneous Recommendations
1. **Caching / CDN** – serve banner images via CDN to reduce load times.
2. **Rate limiting** – add gentle throttling to booking endpoints to prevent spam, but allow the slot summary endpoint to be high-frequency (client polls every second until WebSocket is implemented).
3. **Proper HTTP status codes** – return 401/403 for auth issues, 422 for validation errors (e.g., slot already booked), and include `message` so Flutter can surface them directly.
4. **Cross-field validations** – ensure `maxPlayers` = `slots.count` * `playersPerTeam`.

---

## Next Steps
1. Update the Spring Boot DTOs + controllers with the missing fields.
2. Extend the admin panel forms to capture prizes, per-kill rewards, scoreboard entries, banner metadata, and filter lists.
3. Regenerate API docs (OpenAPI/Swagger) so Flutter devs can verify the fields.
4. Once backend changes are deployed, let the Flutter client fetch and display them; no additional client changes are required beyond pointing to the updated endpoints.

