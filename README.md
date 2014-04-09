# 概要
このツールは、opencv_createsamplesに読み込ませる、
アノテーションファイルを生成するために、作りました。

保存したデータは、annotation.txtとして、終了時に保存します。

「OpenCV_haartraining -BaseFormatSave」で生成されたカスケードファイルcasscade.xmlが存在する場合、
読み込んで青い四角で、囲んでみたりします。annnotation.txtとして、保存しているわけではありません。
サンプルとして、顔を検知して囲むカスケードを置いときます。

# 使い方
四角で囲みたい画像を img/ディレクトリに置いてください。

下記コマンドで実行します。

```
# 初回起動時のみ
% bundle

# 起動
% ruby ./annotation_tool.rb

# 画像ディレクトリ指定可能
% ruby ./annotation_tool.rb img/
```

画像に対して、マウスをドラッグすると、始点と終点に対して、赤い四角で囲みます。
ObjectMarker.extとおなじかんじでつくっています。
間違ったらdで消してください。
次に進みたい場合はEnterを押して下さい。


## ショートカットキー

```
Enter
次の画像へ

Esc
終了 保存されません。

s
アノテーションを保存

d
直前に保存された、アノテーションを削除

x
opencv_traincascade実行時に必要な、nagativelist生成のため、
ng_list.txtというファイル名で現在表示されてるファイルパスを保存します。
重複チェックしてないです。

1..9
線の太さ変更。途中まで実装
```

# todo
- 囲み中に線を引くのではなく、四角で表示
- ng_list.txt用に重複チェック
- 線の太さ変更
