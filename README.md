# vpngw-env

## はじめに
本 Bicep は VPNGW の環境を作成するBicepです。 [vnet-peering-base-env](https://github.com/takutsu001/vnet-peering-base-env) の Bicep で作成される環境に対し `Onpre-VNet` と `Hub-VNet` に存在する GatewaySubnet に VPN Gateway を作成し、それぞれの VPN Gateway を接続させています（経路情報交換はBGPではなくルートベース）。

## 構成図
![](/images/vpngw-topology.png)

> [!NOTE]
> - 本環境では Azure Firewall は作成されません (vnet-peering-base-env をベースにしているため `AzureFirewallSubnet` は作成されますが利用しません) 

> [!WARNING]
> 本環境は HUB の踏み台サーバーを経由して Spokeやオンプレ の VM にアクセスするような構成です。NSG で SSH(22) への接続を許可するルールを作成していますが、セキュリティリスクが高いため、あくまでも検証用途としてご利用ください（本来は Azure Bastion や Azure Firewall を利用して踏み台サーバーへアクセスさせるべきですが、費用を下げるため NSG で穴あけを行っています）

### 前提条件
ローカルPCでBicepを実行する場合は Azure CLI と Bicep CLI のインストールが必要となります。私はVS Code (Visual Studio Code) を利用してBicepファイルを作成しているのですが、結構使いやすいのでおススメです。以下リンクに VS Code、Azure CLI、Bicep CLI のインストール手順が纏まっています

https://learn.microsoft.com/ja-jp/azure/azure-resource-manager/bicep/install

## 使い方
本リポジトリをローカルPCにクローンし、パラメータファイル (main.prod.bicepparam) を修正してご利用ください

**main.prod.bicepparam**
![](/images/vpngw-bicepparam.png)

> [!IMPORTANT]
> NSGルール作成用の ***myipaddress*** の修正は必須となります。それ以外のパラメータの修正は任意で実施してください。Azureに接続するクライアントのパブリックIPアドレスが分からない場合は[こちらのサイト](https://www.cman.jp/network/support/go_access.cgi)で確認することができます

※Git を利用できる環境ではない場合はファイルをダウンロードしていただくでも問題ないと思います。その場合は、以下の構成でローカルPCにファイルを設置してください

```
main.bicep
main.prod.bicepparam
∟ modules/
　　∟ hubEnv.bicep
　　∟ onpreEnv.bicep
　　∟ spoke1Env.bicep
　　∟ spoke2Env.bicep
　　∟ vpnConnection.bicep
```

## 実行手順 (Git bash)

#### 1. Azureへのログインと利用するサブスクリプションの指定
```
az login
az account set --subscription <利用するサブスクリプション名>
```
> [!NOTE]
> az login を実行するとWebブラウザが起動するので、WebブラウザにてAzureへのログインを行う

#### 2. ディレクトリの移動（main.bicep を設置したディレクトリへ移動）
```
cd <main.bicepを設置したディレクトリ>
```

#### 3. デプロイの実行
```
az deployment sub create --location japaneast -f main.bicep -p main.prod.bicepparam
```
> [!NOTE]
> コマンドで指定する `--location` はメタデータを格納する場所の指定で、Azure リソースのデプロイ先ではない (メタデータなのでどこでも問題ないが、特に要件がなければAzureリソースと同一の場所を指定するで問題ない) 

#### 4. Azureからのログアウト
```
az logout
```

## その他
 - 本Bicepは [vnet-peering-base-env](https://github.com/takutsu001/vnet-peering-base-env) をベースに作成しています
 - 本Bicepでは hub 踏み台サーバ (hub-jump-centos) のパブリックIP に対する DNS レコードの登録は削除しています