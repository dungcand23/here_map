# HERE Map Route Planner (Phase 2.5 - Backend-ready B2B-lite)

Flutter app demo: **HERE Autosuggest + Multi-stop Routing** (Web / Mobile WebView).

## What's included (Phase 0 + Phase 1 + Phase 1.1 + Phase 2 + Phase 2.5)

### Phase 0 (Foundation)
- ✅ **No hardcoded HERE API key** in repo (Web + Mobile WebView).
- ✅ Inject key at runtime via `--dart-define=HERE_API_KEY=...`.
- ✅ Real GPS location (Geolocator) with fallback.
- ✅ Better error handling (no app crash on HTTP/API errors).

### Phase 1 (Measurement)
- ✅ Local analytics (event schema) persisted via SharedPreferences.
- ✅ In-app **Analytics Dashboard** (KPIs + recent events + export JSONL).

### Phase 1.1 (Dev ergonomics)
- ✅ `env.example.json` + `--dart-define-from-file` hỗ trợ chạy dev nhanh.
- ✅ Script `run_dev.sh` (mobile) / `run_web.sh` (web).
- ✅ VS Code launch config `.vscode/launch.json`.

### Phase 2 (B2B-lite - Team & Share)
- ✅ **Local sign-in** (email + display name) để mô phỏng auth (không phụ thuộc Firebase).
- ✅ **Team workspace**: tạo/join team bằng join code.
- ✅ **RBAC**: owner/dispatcher/driver (owner mới đổi role).
- ✅ **Team routes (local backend)**: lưu tuyến vào team, list/xóa.
- ✅ **Share tuyến**: xuất **share link + QR** (web) + share code backup.
- ✅ **Import share code/link**: nhập tuyến vào app và tự lưu local.

### Phase 2.5 (Backend-ready refactor)
- ✅ Tách **contract layer**: `AuthRepository`, `TeamRepository`, `RouteRepository`, `ShareRepository`, `SessionStore`.
- ✅ Bọc DI thành `B2BContainer` để UI/State không phụ thuộc implementation.
- ✅ `B2B_BACKEND_MODE`:
  - `local` (default): chạy demo offline như Phase 2.
  - `wms`: dùng stub repository (HTTP) — sẵn khung để cắm API WMS thật ở Phase 3/4.
- ✅ Share/import không còn gọi thẳng `ShareUtils.decode/encode` ở UI mà đi qua `ShareRepository`.

## Run

### 0) Quickstart (recommended)
1) Copy env

```bash
cp env.example.json env.dev.json
```

2) Fill `HERE_API_KEY` in `env.dev.json`.
   - Optional: set `B2B_BACKEND_MODE` = `local` (default) hoặc `wms`.
   - Nếu `wms`: set `WMS_BASE_URL`.

3) Run

```bash
./run_dev.sh
# or
./run_web.sh
```

### 1) Set HERE API key (manual)
Pass it at runtime:

```bash
flutter run --dart-define=HERE_API_KEY=YOUR_KEY
```

Web:

```bash
flutter run -d chrome --dart-define=HERE_API_KEY=YOUR_KEY
```

> Tip: Use different keys per environment and restrict them by domain/bundleId.

### 2) Open Analytics Dashboard
In the bottom panel footer, tap the **Insights** icon (📈) to open the dashboard.

Dashboard shows:
- Route requests / success rate
- Route latency p50 / p95
- Search → select rate
- Recent events
- Export last 500 events as JSONL

## Notes
- This project uses HERE JS (map render) + HERE REST APIs (autosuggest / routing / browse).
- Windows map view is not implemented yet (placeholder).

## B2B-lite usage
- Tap **Team** ở footer để đăng nhập (local) và tạo/join team.
- Khi đã có route, nút **Lưu team** sẽ hiện nếu bạn là owner/dispatcher.
- Nút **Share** sẽ tạo QR + link dạng `/?code=...` (web) và share code backup.
