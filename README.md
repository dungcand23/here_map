## Cấu trúc lib rút gọn

Bản này đã ghép `lib/` xuống còn 5 file chính để dễ mở nhanh trong Android Studio / VS Code:

- `lib/main.dart`
- `lib/app_core.dart`
- `lib/app_config.dart`
- `lib/map_view_web.dart`
- `lib/map_view_io.dart`

`app_core.dart` giữ toàn bộ core logic, còn 2 file map tách riêng theo nền tảng để tránh lỗi build.

---

# HERE Map Route Planner

Flutter app demo cho HERE Autosuggest + auto route + multi-stop routing.
Ban patch nay uu tien chay duoc tren **Windows desktop** truoc, sau do moi den web/mobile.

## Diem da duoc sua trong ban nay

- Da bat **Windows map inline** bang WebView2, khong con placeholder.
- Van su dung **HERE Maps JS** de render map trong desktop app.
- Autosuggest da co **fallback sang geocode** de giam loi khi go dia chi.
- Route builder uu tien:
  1. autosuggest / geocode
  2. optimize stop order
  3. routing v8
  4. ve polyline encoded len map
- Da giu san `HERE_API_KEY` trong:
  - `lib/app_env_defaults.dart`
  - `env.dev.json`

## Chay nhanh

### Windows desktop
```bat
flutter pub get
flutter run -d windows
```

Hoac:
```bat
run_windows.bat
```

### Build file .exe
```bat
build_windows_release.bat
```

File build release se nam o:
```text
build\windows\x64\runner\Release\here_map.exe
```

### Web
```bash
flutter run -d chrome --dart-define-from-file=env.dev.json
```

## Neu Windows khong hien map

Kiem tra theo thu tu nay:

1. `flutter pub get`
2. `flutter run -d windows`
3. May co **Microsoft Edge WebView2 Runtime**
4. Co internet de HERE JS tai tile/script
5. HERE key con hieu luc

## Cau hinh

Ban nay da kem san:
- `env.dev.json`
- fallback key trong `lib/app_env_defaults.dart`

Nghia la ban co the chay ngay ma khong can sua key nua.

## Ghi chu

- Web van co the gap loi do browser/restriction, nhung Windows desktop se on dinh hon cho luong autosuggest/routing.
- Neu sau nay ban day source len repo public, nen xoa key khoi source va rotate key.
