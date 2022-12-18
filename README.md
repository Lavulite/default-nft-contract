# default-nft-contract

## Summary

本ライブラリは現在開発中であり、**テスト未済**です。
利用する場合は自己責任でお願いします。

標準的なNFTの機能を備えたコントラクトです。
このプロジェクトで提供するコントラクトを利用することで、よくある機能の実装・テストに時間をかけなくても良くなり、独自ギミック等に注力できます。

## 種類

- [NFT](./contracts/tokens/NFT/BasicNFTByMarkleForMultiWallets.sol) : ERC721ベースのNFT
- [NonFungibleSBT](./contracts/tokens/NonFungibleSBT/BasicNonFungibleSBT.sol) : ERC721ベースのSBT
- [FungibleSBT](./contracts/tokens/FungibleSBT/BasicFungibleSBT.sol) : ERC1155ベースのSBT

## NFT(BasicNFTByMarkleForMultiWallets)

### 使い方

以下のように継承してコンストラクタに、`コレクション名`、`コレクション略称`、`寄付率`を指定するだけで利用できます。
寄付率は0にしても利用可能です。
もし本プロジェクトの開発者に売り上げの一部を寄付してくださる利用者の方がいれば1以上の数字を設定してください。

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "./BasicNFTByMarkleForMultiWallets.sol";

contract SampleBasicNFTByMarkleForMultiWallets is
    BasicNFTByMarkleForMultiWallets
{
    // If you are willing to donate, please set the third argument to a number between 1 (0.01%) and 10000 (100%),
    // and the percentage you set will be donated to the library developer when you withdraw.
    constructor() BasicNFTByMarkleForMultiWallets("SampleNFT", "SNFT", 1000) {}
}
```

### 機能

主な機能は以下の通りです。

#### セール

[ERC721MultiSale](https://github.com/Lavulite/ERC721MultiSale)を利用した複数回のセールを実装しています。
ALはマークルツリーを採用しています。
同一人物の複数ウォレットについて、ALと購入数を一元管理できます。

どのウォレットが同一人物のものであるかの確認は本プロジェクトのスコープ外です。
別途、ご確認の上ご利用ください。

#### エアドロップ

管理者から複数のウォレット宛てに一括でミントできます。

#### 交換

NFTをバーンし、新しいNFTを入手する機能です。(NinjaDAO界隈での所謂バー忍)

#### OpenSeaのクリエイターフィーを受け取るための実装

OpenSeaのクリエイターフィーを受け取るための実装を入れてあります。
ERC2981の実装も入っているため、2023/1月から適用されるルールにも対応しています。

#### approveの抑制

[ContractAllowList](https://github.com/masataka-eth/ContractAllowList)を用いて、信頼できるコントラクトのみapprove可能としています。

#### ロック

ホルダーの意思でNFTのtransferを抑制できるようにしています。
機能は[CNP Reborn](https://site.cnp-reborn.com/)の[リボロック](https://lock.cnp-reborn.com/)と同様です。

ロックには以下の二種類があります。

- トークンロック(Token lock)：  
  1つ1つロック・アンロックを行う方法です。
- ウォレットロック(Wallet lock)：  
  ウォレット指定でロック・アンロックを行う方法です。 ウォレットロック中のウォレットに新たにトークンを入れると自動的にロックされます。
  多数のトークンをトークンロックするよりもウォレットロックの方がガス代が安くなります。

トークンロックの方がウォレットロックよりも優先されます。 例えばウォレットロック中でもトークンアンロックすれば、一部のトークンをアンロックできます。

ロック状態のトークンをアンロックした場合、アンロック操作してから3時間はロック状態が継続されます。
これはアンロックとトランスファーを行わせるスキャムサイトが登場してもすぐにトランスファーできないことでホルダーを守るための仕組みです。

ロック中はトークンURLの拡張子前に`_lock`が付きます。
これにより、ロック中のみ画像を特別なものに差し替えることができます。
利用しない場合はoverrideして`_lock`が付かないようにしてください。

#### オフチェーンメタデータ・フルオンチェーン切り替え対応

デフォルト実装ではオフチェーンにメタデータが存在する前提の実装ですが、外部コントラクトからtokenURIを受け取る用切り替えられるようにしてあります。

## NonFungibleSBT(BasicNonFungibleSBT)

工事中

## FungibleSBT(BasicFungibleSBT)

工事中