# KinoFree: iOS, этап 1

## Область переноса

Существующий SvelteKit adapter-static формирует `build/`, который Tauri загружает
в WKWebView. Интерфейс и существующий Android-плеер не переписаны.
Bundle ID: `su.kinofree.app`, minimum iOS: 15.0. Tauri автоматически объединяет
`tauri.conf.json` и `tauri.ios.conf.json` только для iOS.
Сертификаты, Apple ID, team ID и provisioning profiles в репозитории не нужны.
Мобильный Rust entry point включён для iOS. Updater исключён из iOS Rust target,
его разрешений и запуска JS (включая iPad с desktop user agent).
Обновлять подписанное iOS-приложение нужно через выбранный канал распространения.

## Сборка и артефакт

На macOS нужны Xcode с iOS SDK, Command Line Tools, Rust stable,
`rustup target add aarch64-apple-ios`, Node 20 и `brew install xcodegen`.
Из корня репозитория:

```sh
npm ci
npm run tauri -- ios init --ci
npm run tauri -- ios build --ci --target aarch64 --no-sign
bash scripts/package-ios.sh
```

Отдельный workflow **iOS unsigned** (`.github/workflows/ios.yml`) запускается
при push в `feature/ios-tauri`, PR в main либо вручную через Actions.
Он использует macOS и не импортирует signing identities.
Скачать: GitHub → Ganzzis/kinofree → Actions → iOS unsigned → успешный запуск
для нужного commit → Artifacts → `KinoFree-ios-unsigned-<commit SHA>`.
Срок хранения: 14 дней. Артефакт содержит:

- `KinoFree-unsigned.ipa`: ZIP с `Payload/*.app` для самостоятельной подписи;
- `KinoFree-xcode-project.zip`: сгенерированный проект и результаты сборки;
- эту инструкцию.

Это упаковка unsigned device application, а не подписанный `xcodebuild -exportArchive`.
IPA нельзя устанавливать напрямую. Подпишите приложение своим инструментом,
совместимым provisioning profile и сертификатом. При ручной подписи подписывайте
вложенные frameworks перед приложением и заново упакуйте Payload.
Альтернатива: распакуйте Xcode-проект в `src-tauri/gen/apple` в checkout того же
commit, откройте `.xcodeproj`, выберите свою Team/Signing и выполните Product →
Archive → Distribute App. Нужны локальные Node/Rust dependencies и доступные
исходники; ZIP проекта не является автономным SDK. При смене bundle ID нужен
соответствующий profile. Симуляторный build не заменяет device build.

## Аудит WKWebView

- Все WebView на iOS используют WebKit, а не Windows WebView2. Chromium
  `additionalBrowserArgs` и DNS-реклама-фильтры из общей конфигурации на iOS
  не действуют. Полноценной блокировки рекламы этот этап не добавляет.
- Видео находится в сторонних HTTPS iframe. Проект не управляет их `<video>`.
  Inline playback требует `playsinline` у поставщика и поддержки конфигурацией
  WKWebView; autoplay со звуком может требовать жеста пользователя. Текущий iframe
  не делегирует autoplay. Гарантий autoplay/inline на этом этапе нет.
- Нативный fullscreen видео зависит от iOS и поставщика. DOM Fullscreen API и
  `screen.orientation.lock` нельзя считать доступными. Android fullscreen ветка
  остаётся только Android; собственного iOS fullscreen здесь нет.
- Предпочтителен HLS с поддерживаемыми системными кодеками. MSE, DASH, DRM
  (Widevine не эквивалентен FairPlay) и произвольные кодеки требуют проверки
  на реальном устройстве. Буферизация, фон, AirPlay и PiP не гарантируются.
- `X-Frame-Options`, CSP `frame-ancestors`, CORS, Referer/origin проверки и
  авторизация поставщика могут запрещать embed. Локальный Tauri origin отличается
  от сайта. Разрешения Tauri и `csp: null` не обходят политику стороннего сервера.
- Iframe sandbox остаётся `allow-scripts allow-same-origin`: popup, переходы,
  загрузки и ряд платёжных/логин-сценариев могут не работать. Расширять sandbox
  без отдельного аудита нельзя. IPC capabilities не предоставлены remote iframe.
- ITP и ограничения third-party cookies/storage могут ломать сессию iframe.
  `postMessage` работает только при поддержке поставщика; существующий обработчик
  сообщений нуждается в отдельном аудите origin/source, не исправлялся здесь.
- ATS не ослаблен: HTTP/mixed content и плохие TLS-сертификаты могут блокироваться.
  PocketBase и film API используют HTTPS, но доступность/CORS требуют device теста.
- Service Worker не является обязательным для static bundle. App-Bound Domains
  не включены: ограничение списка доменов несовместимо с произвольными провайдерами.
- Общая CSP остаётся отключённой, как в исходном проекте. Это существующее
  ограничение безопасности; ужесточение CSP требует отдельного тестирования iframe.

## Проверки и границы

Windows/Android release workflow и Android generated project не изменены.
Их общий Tauri config сохранён; desktop updater dependency и runtime plugin
сохраняются на всех прежних targets. Default capability сохраняет прежние
разрешения для Windows/macOS/Linux/Android; iOS использует отдельную capability.
Web updater сохраняет desktop и Android пути, пропуская только iOS.

В Linux нет Xcode/iOS SDK, Rust в текущем окружении отсутствует, а Linux Tauri CLI
не предоставляет `ios`. Нативные Windows/Android/iOS сборки локально не подтверждены.
Нужен успешный macOS workflow для подтверждения iOS compile и упаковки.
Перед распространением на устройстве проверить: cold start, deep navigation,
PocketBase login, внешний HTTPS URL, каждый iframe, ручной запуск видео, seek,
fullscreen/возврат, поворот, background/foreground и повторный запуск.

### Результаты локального запуска

- `npm run build`: PASS, static build сформирован.
- `npm run check`: PASS, 0 ошибок, 16 предупреждений в 2 файлах.
- `node --test scripts/ios-platform.test.mjs`: PASS, 5 сценариев определения платформы.
- `bash -n scripts/package-ios.sh`, YAML parsing, `git diff --check`: PASS.
- Сравнение с исходным commit: release workflow, общий Tauri config,
  tracked Android project и прежние permissions не изменены.
- `npm run lint`: FAIL на Prettier (65 файлов); ESLint через этот script не запущен.
  Несвязанные ошибки форматирования не исправлялись.
- Отдельный `npx eslint .`: FAIL, 13 существующих ошибок; не исправлялись.
- Native compilation: не выполнена (Linux без Rust/Xcode).
- GitHub push/CI/PR: недоступны в текущей сессии из-за отказа подключения к
  `proxy:8080`; `gh auth status` также сообщает ошибку токена. Артефакт ещё не собран.
