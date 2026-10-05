# AS660 → Typeless (macOS)

AfterShokz OpenMove（AS660）のマルチファンクションボタンで、Typelessの音声入力を開始・停止する実験的なmacOS用ツールです。AS660を入力マイクに使い、Macから離れて音声入力するために作成しました。

## 動作確認した設定

- Typelessの入力マイク：AS660
- Typelessの音声入力ショートカット：右Shift（押すたびに開始・停止）
- macOSのSiri：オフ

この設定で、ユーザーの実機においてボタンによる開始・停止を確認しました。AS660のマイク使用中にSiriを有効にしていると、2回目のボタン操作でSiriが起動し、本ツールにコマンドが届きませんでした。Siriをオフにすると停止操作も動作しました。他の機種やmacOSバージョンでの動作は未検証です。

## 仕組みと制限

`MPRemoteCommandCenter`で再生・停止コマンドを受け、`CGEvent`で右Shiftの押下・解放を送ります。音声の録音・送信は行いません。音声入力はTypelessが行います。

- AS660専用の信号を識別していません。他のメディアキーやコントロールセンターの操作にも反応する可能性があります。
- 音楽・動画アプリがコマンドの受信先になると、本ツールに届かなくなる可能性があります。
- コントロールセンターには本ツールの再生情報が表示されます。実際の音声は再生しません。
- Bluetooth再接続後やスリープ復帰後の継続動作は未検証です。
- 0.4秒以内の連続コマンドは重複防止のため無視します。
- Siriをオフにする必要があるため、同時にSiriを使う運用は確認していません。

## セットアップ

Swiftコンパイラ（XcodeまたはCommand Line Tools）と、インストール用のPython 3が必要です。Karabinerは不要です。

```bash
./build.sh
./as660-typeless
```

初回は「システム設定 → プライバシーとセキュリティ → アクセシビリティ」で本実行ファイルへの許可が必要です。ターミナルからの実行と自動起動で権限の扱いが異なる場合があります。必要なら「＋」からビルドした `as660-typeless` を直接追加してください。許可後に再実行します。

「システム設定 → Apple IntelligenceとSiri（またはSiri）」でSiri本体をオフにし、Typelessのマイクとショートカットを上記の設定にします。`READY`が表示されたらボタンを試します。終了はControl+Cです。

## ログイン時の自動起動

手動で動作確認したプログラムをControl+Cで終了してから実行します。二重起動しないようにしてください。

```bash
./install-autostart.sh
```

ユーザーのLaunchAgentを登録し、すぐに起動します。Mac起動後のユーザーログイン時に起動し、終了した場合は再起動します。ログイン前は動作しません。リポジトリの絶対パスを登録するため、フォルダを移動した場合は再インストールしてください。

状態とログ：

```bash
launchctl print "gui/$(id -u)/local.as660.typeless"
tail -n 30 ~/Library/Logs/as660-typeless/stdout.log
tail -n 30 ~/Library/Logs/as660-typeless/stderr.log
```

アクセシビリティの許可エラーが出る場合は実行ファイルを許可し、次のコマンドで再起動します。

```bash
launchctl kickstart -k "gui/$(id -u)/local.as660.typeless"
```

自動起動の解除：

```bash
./uninstall-autostart.sh
```

## 診断ソース

- `diagnose.swift`：システム定義イベントを監視。今回のAS660環境ではボタンを取得できませんでした。
- `diagnose-remote.swift`：再生・停止コマンドをログ表示。キー操作は送りません。

## 参考

発想のきっかけは[じゃが氏のOpenComm2 UCの記事](https://note.com/jaga_farm/n/nee6c8143459c)です。記事はLoop120のUSB HIDイベントを扱います。本ツールはBluetooth接続でメディアコマンドを受信する別の実装で、Loop120は使用しません。

## ライセンス

MIT License。Shokz、Typeless、Appleの公式ツールではありません。
