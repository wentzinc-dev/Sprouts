# Sprouts Project Memory

- 状態: `current`
- 最終確認: 2026-08-29
- repository: `wentzinc-dev/Sprouts`
- branch: `master`
- latest_evidence_commit: `cfde9f8af6aba7400b40230aebf7d35839b9f79e`
- source_at: `2026-08-29T23:51:00+09:00`

## Current Context

```yaml
current_context:
  project: Sprouts
  topic: macos-image-conversion
  subtopic: app-store-v1.1-release
  continuation_target: continue from Sprouts 1.1 build 2 on master, complete the App Store archive/upload with a current stable Xcode, then handle later maintenance from repository evidence
```

## Current State

- SproutsはmacOSネイティブの画像変換アプリ。処理はローカルで完結し、入力ファイルをネットワークへ送信しない。
- 旧PDFUNK系の名称・内部名はSproutsへ統合済み。現行Xcode Project / Scheme / Target / app名はSprouts。
- 2026-08-21の中央Portfolio Memoryでは、完成済み・App Store審査中としてユーザー確認済み。
- 直近のmasterでは、旧PDFUNK内部名の残りをSproutsへ変更し、persistent folder access、support pages、App Store metadata等を統合している。
- App Sandboxとsecurity-scoped bookmarkによる永続フォルダアクセスを維持する。
- `master` commit `c4ac5ae`でSprouts 1.1のVersion / Buildを`1.1 (2)`へ更新し、変換中止、応答性改善、入力検査の軽量化、回帰テストを統合済み。
- `master` commit `cfde9f8`でJPEG書き出しが通常のベースライン形式であり、Photoshopの「ベースライン（標準）」に近いが同一ではないことをヘルプとサポートに明記。

## Current Product Capabilities

- 入力: PNG / JPG / JPEG / PDF / PSD（統合画像） / TIF / TIFF / GIF / WebP。
- 出力: JPG / PNG / TIF / WebP。複数形式を同時出力できる。
- サイズ指定、PDF読込解像度、リサイズ方式、カラー、ICC、メタデータ、作成日時、ファイル名加工を扱う。
- 複数形式を含むプリセット保存・適用・削除・`.sproutpreset`書き出しに対応。
- 保存先は同じ場所または選択フォルダ。形式名フォルダ利用と永続フォルダアクセスを扱う。
- 変換中はボタンまたは`⌘.`で中止を要求できる。ImageIO / WebP等の同期ネイティブ処理は即時割り込みできないため、処理中の1枚が終了後に停止する場合がある。
- README上の開発環境はXcode 16以降。

## Important Boundaries

- PSDは入力時に保存済み統合画像を読むが、PSD出力とレイヤー保持はしない。色再現は保証せず、厳密な色管理が必要な案件ではPhotoshop等からの書き出しを推奨する。
- 試作したPSD / PSB ICCプロファイル改善は不採用。PSB対応もCurrentに含めない。
- JPEG品質は1〜100のまま。Photoshop独自の0〜12との直接対応はなく、最適化・プログレッシブ選択は未実装。
- GIFは先頭フレーム。TIFFは複数画像を含む場合に各画像を扱う。
- ネットワーク権限を変換処理のために追加しない。
- `docs/HANDOFF.md`には過去branch・暫定値も含まれるため、Current判定ではmasterのREADME / 実装 / newer commitを優先する。

## Current Evidence

- `README.md` — 現行形式、UI、Sandbox、開発条件。
- commit `cfde9f8` — JPEG baseline書き出しの説明をアプリ内ヘルプとGitHubサポートへ追加。
- commit `c4ac5ae` — Sprouts 1.1 build 2、変換中止、軽量な入力検査、WebPを含む回帰テストをmasterへ統合。
- commit `8a50b58` — persistent folder access setupをmasterへ統合。
- commit `ac8a3b2` — remaining PDFUNK internalsをSproutsへrename。
- WENTZ-Knowledge `projects/app-portfolio/status-2026-08-21.md` — completed / under App Store reviewとしてユーザー確認済み。

## Memory Rules

- PDFUNKを独立Current Projectとして復活させず、Sproutsの履歴・旧称として扱う。
- HANDOFF内の古いbranchや暫定Bundle情報を、より新しいmaster Evidenceより優先しない。
- 製品固有のCurrentはこのrepoを正本とする。
