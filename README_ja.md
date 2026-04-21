# twsnmpfm (日本語)

[English Version](README.md)

TWSNMP For Mobile - ポケットに入る本格的ネットワーク管理ツール

## 概要

TWSNMP For Mobileは、長年親しまれているSNMPマネージャ「TWSNMP」のモバイル版です。ネットワーク管理者が外出先からでもネットワークインフラを監視・管理できるように設計されています。

## 主な機能

- **ノード管理**: ネットワーク機器をノードとして登録し、アイコン（サーバー、PC、ネットワーク、クラウド）で視覚的に分類・管理できます。
- **応答確認**:
  - PINGによる定期・手動の応答確認。
  - SSL/TLSサーバー証明書の有効期限および妥当性のチェック。
- **SNMP監視ツール**:
  - **MIBブラウザー**: MIBツリーを探索し、SNMP v1/v2cでオブジェクトの値を取得。
  - **トラフィックモニター**: 通信量をリアルタイムでグラフ表示。
  - **仮想パネル**: LANポートのリンク状態（Up/Down）をパネル形式で表示。
  - **ホストリソース**: CPU、メモリ、ディスクの使用量を監視（Host Resource MIB）。
  - **プロセスリスト**: 動作中のプロセス一覧を取得.
  - **ポートリスト**: TCP/UDPポートの待機・通信状態を確認。
- **サーバーテスト**:
  - SyslogメッセージやSNMPトラップの送信テスト。
  - DHCPメッセージのモニタリング。
  - メール（SMTP）送信テスト。
- **ネットワーク検索ユーティリティ**:
  - DNS検索（A, AAAA, PTRなど）とIP検索。
  - MACアドレスによるベンダー名の検索（内蔵データベースを使用）。
- **モダンなUI**:
  - ライトモードとダークモードに対応。
  - 「TWSNMP Blueprint」デザインシステムに基づいた直感的な操作感。
  - 日本語と英語のバイリンガル対応。

## ステータス
最初のバージョンをリリース済み。

- **iOS**: [App Store](https://apps.apple.com/jp/app/twsnmp-for-mobile/id1630463521)

## ビルド方法

ソースコードからビルドするには、[Flutter SDK](https://docs.flutter.dev/get-started/install)がインストールされている必要があります。

1. **リポジトリのクローン**:
   ```bash
   git clone https://github.com/twsnmp/twsnmpfm.git
   cd twsnmpfm
   ```
2. **依存関係のインストール**:
   ```bash
   flutter pub get
   ```
3. **アプリの実行**:
   ```bash
   flutter run
   ```
4. **プラットフォーム別のビルド**:
   - **Android**: `flutter build apk`
   - **iOS**: `flutter build ios`
   - **macOS**: `flutter build macos`

### mise を使用したビルド

このプロジェクトでは、開発ツールとビルドタスクの管理に [mise](https://mise.jdx.dev/) を使用しています。

1. **ツールのインストール**:
   ```bash
   mise install
   ```
2. **環境のセットアップ (初回のみ)**:
   Android SDKコンポーネントとCocoaPodsをインストールします。
   ```bash
   mise run setup
   ```
3. **APK のビルド**:
   ```bash
   mise run build:apk
   ```
4. **iOS IPA のビルド**:
   ```bash
   mise run build:ios
   ```

### ビルドの注意事項

- **Android SDK:** `flutter doctor` でSDKが見つからない場合は、`flutter config --android-sdk ~/Library/Android/sdk` を実行してパスを設定してください。
- **Xcode Components:** iOSビルドで "iOS SDK not installed" エラーが出る場合は、Xcode の `Settings > Components` から必要な iOS プラットフォームをダウンロードしてください。
- **Info.plist:** `ios/Runner/Info.plist` はビルドに必須です。誤って削除しないよう注意してください。

## CI/CD

GitHub Actions を使用して、Android APK を自動的にビルドします。
- **トリガー**: `v` で始まるタグ（例: `v1.0.0`）をプッシュした時。
- **アーティファクト**: 生成された APK は GitHub のリリースに自動的にアップロードされます。

## 操作方法

1. **ノードの追加**: メイン画面の **+** ボタンをタップしてデバイスを登録します。名前、IPアドレス、SNMPコミュニティ名を入力してください。
2. **ステータスの確認**: メインリストにはPINGと証明書のステータスが表示されます。緑色は正常、赤や黄色は問題があることを示します。
3. **ツールの使用**: 各ノードの **三点リーダーメニュー** をタップすると、MIBブラウザーやトラフィックモニターなどの詳細ツールを起動できます。
4. **一括チェック**: 上部バーの **再生アイコン** から、全ノードに対して一括でPINGや証明書チェックを実行できます。
5. **検索**: 上部バーの **検索アイコン** から、DNS検索やMACアドレス検索が可能です。
6. **設定**: 上部バーの **歯車アイコン** から、チェックの間隔、タイムアウト、テーマや言語の設定の切り替えなどが可能です。

## Copyright

see ./LICENSE

```
Copyright 2022-2026 Masayuki Yamai
```

