# ヘッドセットのマイク使用中のボタン操作の調査

## 実機で分かったこと

- AS660のボタンは、外部マイク使用時にMPRemoteCommandCenterへ届き、Typelessの開始・停止に変換できる。
- AS660自身のマイク使用時は、2回目の操作でSiriまたはSiriの有効化画面が表示され、ブリッジへのコールバックがない。
- Siriを無効化するだけでは解決しない。

## 公開資料とSDKの確認

AppleのAccessory Design Guidelinesは、BluetoothヘッドセットによるSiri起動にHFPの `AT+BVRA` を使用することを説明している。ただし、今回のAS660が実際に送ったコマンドはまだ捕捉していない。

`IOBluetoothHandsFreeAudioGateway.process(atCommand:)` は、自分が管理するゲートウェイでコマンド処理を変更する公開API。macOSが管理している既存のヘッドセット接続を受動監視するAPIとしての保証はない。

`IOBluetoothRFCOMMChannel.registerForChannelOpenNotifications` は接続通知であり、ボタン操作のデータ監視ではない。`setDelegate` も受動監視としては採用していない。

## 次の切り分け

まず `./diagnose-hfp.sh` をターミナルで実行し、AS660マイクで入力中にボタンを押してログが出るか確認する。キーの送信・接続変更・設定変更はしない。通常のシステムログにATコマンドが出ない場合もあるため、何も出なくてもHFPコマンドが存在しない証拠にはならない。

ログで確認できない場合はAppleのPacketLoggerによる受動キャプチャを検討する。PacketLoggerはAdditional Tools for Xcodeに含まれる。現在このMacへのインストールは確認できていない。通信を捕捉できても、公開APIで取得・抑止できることの証明にはならない。

## 参考

- [Apple Accessory Design Guidelines（Bluetooth SIG掲載のApple資料）](https://www.bluetooth.com/wp-content/uploads/attachments/BluetoothDesignGuidelines.pdf)
- [Apple: process(atCommand:)](https://developer.apple.com/documentation/iobluetooth/iobluetoothhandsfreeaudiogateway/process(atcommand:))
- [Apple: Bluetooth / PacketLogger](https://developer.apple.com/bluetooth/)

## ログ経由の実験結果と統合

ユーザーの実機では、AS660マイク使用中の短押し3回でそれぞれ `Received End Voice Command - Deactivating Siri` が記録された。この通知を右Shiftに変換する実験版で、Typelessの停止と文字入力を確認し、その試行でSiriの画面は表示されなかった。これはSiriの抑止を実装した結果ではない。

統合版では再生コマンドとログの両方を共通のキー送信処理へ渡す。1秒以内の重複を無視し、ログ監視の子プロセスを終了時に停止する。ログ監視は既定で有効で、`--media-only` で無効化可能。統合後の繰り返し操作・再接続・再起動後の確認は未完了。
