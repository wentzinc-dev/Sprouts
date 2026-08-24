# Sprouts Project Memory

- 状態: `current`
- 最終確認: 2026-08-24
- repository: `wentzinc-dev/Sprouts`
- branch: `master`
- latest_evidence_commit: `8a50b58fa1442a0f75e53d0c3215310e9ec3a2f8`
- source_at: `2026-08-19T12:16:09+09:00`

## Current Context

```yaml
current_context:
  project: Sprouts
  topic: macos-image-conversion
  subtopic: app-store-review-and-post-v1-maintenance
  continuation_target: continue from the completed Sprouts product state, current review/distribution work, and any later v2 UI or export refinements supported by repository evidence
```

## Current State

- SproutsはmacOSネイティブの画像変換アプリ。処理はローカルで完結し、入力ファイルをネットワークへ送信しない。
- 旧PDFUNK系の名称・内部名はSproutsへ統合済み。現行Xcode Project / Scheme / Target / app名はSprouts。
- 2026-08-21の中央Portfolio Memoryでは、完成済み・App Store審査中としてユーザー確認済み。
- 直近のmasterでは、旧PDFUNK内部名の残りをSproutsへ変更し、persistent folder access、support pages、App Store metadata等を統合している。
- App Sandboxとsecurity-scoped bookmarkによる永続フォルダアクセスを維持する。

## Current Product Capabilities

- 入力: PNG / JPG / JPEG / PDF / PSD（統合画像） / TIF / TIFF / GIF / WebP。
- 出力: JPG / PNG / TIF / WebP。複数形式を同時出力できる。
- サイズ指定、PDF読込解像度、リサイズ方式、カラー、ICC、メタデータ、作成日時、ファイル名加工を扱う。
- 複数形式を含むプリセット保存・適用・削除・`.sproutpreset`書き出しに対応。
- 保存先は同じ場所または選択フォルダ。形式名フォルダ利用と永続フォルダアクセスを扱う。
- README上の開発環境はXcode 16以降。

## Important Boundaries

- PSDは入力時に保存済み統合画像を読むが、PSD出力とレイヤー保持はしない。
- GIFは先頭フレーム。TIFFは複数画像を含む場合に各画像を扱う。
- ネットワーク権限を変換処理のために追加しない。
- `docs/HANDOFF.md`には過去branch・暫定値も含まれるため、Current判定ではmasterのREADME / 実装 / newer commitを優先する。

## Current Evidence

- `README.md` — 現行形式、UI、Sandbox、開発条件。
- commit `8a50b58` — persistent folder access setupをmasterへ統合。
- commit `ac8a3b2` — remaining PDFUNK internalsをSproutsへrename。
- WENTZ-Knowledge `projects/app-portfolio/status-2026-08-21.md` — completed / under App Store reviewとしてユーザー確認済み。

## Memory Rules

- PDFUNKを独立Current Projectとして復活させず、Sproutsの履歴・旧称として扱う。
- HANDOFF内の古いbranchや暫定Bundle情報を、より新しいmaster Evidenceより優先しない。
- 製品固有のCurrentはこのrepoを正本とする。
