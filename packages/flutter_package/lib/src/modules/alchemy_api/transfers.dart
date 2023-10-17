// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:convert';

import 'package:pks_4337_sdk/pks_4337_sdk.dart';
import 'package:pks_4337_sdk/src/modules/alchemy_api/utils/enum.dart';
import 'package:pks_4337_sdk/src/modules/alchemy_api/utils/metadatas.dart';
import 'package:web3dart/web3dart.dart';

class RawContract {
  final Uint256? value;
  final String? address;
  final Uint256? decimal;

  RawContract({
    this.value,
    this.address,
    this.decimal,
  });

  factory RawContract.fromJson(String source) =>
      RawContract.fromMap(json.decode(source) as Map<String, dynamic>);

  factory RawContract.fromMap(Map<String, dynamic> map) {
    return RawContract(
      value: map['value'] != null ? Uint256.fromHex(map['value']) : null,
      address: map['address'] != null ? map['address'] as String : null,
      decimal: map['decimal'] != null ? Uint256.fromHex(map['decimal']) : null,
    );
  }

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'value': value?.toHex(),
      'address': address,
      'decimal': decimal?.toHex(),
    };
  }
}

/// uses alchemy transfer api
/// if want to use another api, you have to DIY
class Transfer {
  final Uint256 blockNum;
  final String uniqueId;
  final String hash;
  final String from;
  final String to;
  final num? value;
  final Uint256? erc721TokenId;
  final ERC1155Metadata? erc1155Metadata;
  final Uint256? tokenId;
  final String? asset;
  final TransferCategory category;
  final RawContract rawContract;
  final DateTime? blockTimestamp;

  Transfer({
    required this.blockNum,
    required this.uniqueId,
    required this.hash,
    required this.from,
    required this.to,
    this.value,
    this.erc721TokenId,
    this.erc1155Metadata,
    this.tokenId,
    this.asset,
    required this.category,
    required this.rawContract,
    this.blockTimestamp,
  });

  factory Transfer.fromJson(String source, ResponseType responseType) =>
      Transfer.fromMap(
          json.decode(source) as Map<String, dynamic>, responseType);

  factory Transfer.fromMap(
      Map<String, dynamic> map, ResponseType responseType) {
    return Transfer(
      blockNum: Uint256.fromHex(map['blockNum']),
      uniqueId: map['uniqueId'] as String,
      hash: map['hash'] as String,
      from: map['from'] as String,
      to: map['to'] as String,
      value: map['value'] != null ? map['value'] as num : null,
      erc721TokenId: map['erc721TokenId'] != null
          ? Uint256.fromHex(map['erc721TokenId'])
          : null,
      erc1155Metadata: map['erc1155Metadata'] != null
          ? ERC1155Metadata.fromMap(
              map['erc1155Metadata'] as Map<String, dynamic>)
          : null,
      tokenId: map['tokenId'] != null ? Uint256.fromHex(map['tokenId']) : null,
      asset: map['asset'] != null ? map['asset'] as String : null,
      category: TransferCategory.values.byName(map['category'] as String),
      rawContract:
          RawContract.fromMap(map['rawContract'] as Map<String, dynamic>),
      blockTimestamp: responseType == ResponseType.withMetadata
          ? DateTime.parse(map['metadata']['blockTimestamp'] as String)
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'blockNum': blockNum.toHex(),
      'uniqueId': uniqueId,
      'hash': hash,
      'from': from,
      'to': to,
      'value': value,
      'erc721TokenId': erc721TokenId?.toHex(),
      'erc1155Metadata': erc1155Metadata?.toMap(),
      'tokenId': tokenId?.toHex(),
      'asset': asset,
      'category': category,
      'rawContract': rawContract.toMap(),
      'blockTimestamp': blockTimestamp,
    };
  }
}

class TransferResponse {
  final List<Transfer> transfers;
  final String? pageKey;
  final ResponseType responseType;

  TransferResponse({
    required this.transfers,
    this.pageKey,
    required this.responseType,
  });
}

class Transfers {
  final BaseProvider _provider;

  Transfers(this._provider);

  /// [getAssetTransfers] returns all transaction to or from [owner]
  /// {@template transfers}
  /// - @param required [owner] is the address or contract to send the transaction to
  /// - @param optional [fromBlock] is the block number to start from
  /// - @param optional [toBlock] is the block number to end at
  /// - @param optional [orderByDesc] is true if you want to sort in descending order
  /// - @param optional [withMetadata] is true if you want to get metadata
  /// - @param optional [excludeZeroValue] is true if you want to exclude zero values
  /// - @param optional [maxCount] is the maximum number of transfers to return
  /// - @param optional [pageKey] a pageKey is returned if there is a next page
  /// {@endtemplate}
  Future<List<Transfer>> getAssetTransfers(EthereumAddress owner,
      {Uint256? fromBlock,
      Uint256? toBlock,
      bool orderByDesc = false,
      bool withMetadata = false,
      bool excludeZeroValue = false,
      Uint256? maxCount,
      String? pageKey}) {
    return getIncomingTransfers(owner).then((res) async {
      res.transfers.addAll(
          await getOutgoingTransfers(owner).then((res2) => res2.transfers));
      return res.transfers;
    });
  }

  /// [getIncomingTransfers] returns all incoming transfers from [owner] only
  /// {@macro transfers}
  Future<TransferResponse> getIncomingTransfers(EthereumAddress owner,
      {Uint256? fromBlock,
      Uint256? toBlock,
      bool orderByDesc = false,
      bool withMetadata = false,
      bool excludeZeroValue = false,
      Uint256? maxCount,
      String? pageKey}) {
    return _getAssetTransfers(
        fromBlock: fromBlock,
        toBlock: toBlock,
        orderByDesc: orderByDesc,
        withMetadata: withMetadata,
        excludeZeroValue: excludeZeroValue,
        maxCount: maxCount,
        pageKey: pageKey,
        to: owner);
  }

  /// [getOutgoingTransfers] returns all outgoing transfers to [owner] only
  /// {@macro transfers}
  Future<TransferResponse> getOutgoingTransfers(EthereumAddress owner,
      {Uint256? fromBlock,
      Uint256? toBlock,
      bool orderByDesc = false,
      bool withMetadata = false,
      bool excludeZeroValue = false,
      Uint256? maxCount,
      String? pageKey}) {
    return _getAssetTransfers(
        fromBlock: fromBlock,
        toBlock: toBlock,
        orderByDesc: orderByDesc,
        withMetadata: withMetadata,
        excludeZeroValue: excludeZeroValue,
        maxCount: maxCount,
        pageKey: pageKey,
        from: owner);
  }

  /// [getTransfersByCategory] returns all transfers by category
  /// - @param required [categories] is the list of categories
  /// {@macro transfers}
  Future<TransferResponse> getTransfersByCategory(
      EthereumAddress owner, List<TransferCategory> categories,
      {Uint256? fromBlock,
      Uint256? toBlock,
      bool orderByDesc = false,
      bool withMetadata = false,
      bool excludeZeroValue = false,
      Uint256? maxCount,
      String? pageKey}) {
    return _getAssetTransfers(
        fromBlock: fromBlock,
        toBlock: toBlock,
        orderByDesc: orderByDesc,
        withMetadata: withMetadata,
        excludeZeroValue: excludeZeroValue,
        maxCount: maxCount,
        pageKey: pageKey,
        categories: categories,
        from: owner);
  }

  /// [getTransfersByContracts] returns all transfers by filtered according to provided contracts
  /// @param required [addresses] is the list of contracts addresses
  /// {@macro transfers}
  Future getTransfersByContracts(
      EthereumAddress owner, List<EthereumAddress> addresses,
      {Uint256? fromBlock,
      Uint256? toBlock,
      bool orderByDesc = false,
      bool withMetadata = false,
      bool excludeZeroValue = false,
      Uint256? maxCount,
      String? pageKey}) {
    return _getAssetTransfers(
      fromBlock: fromBlock,
      toBlock: toBlock,
      orderByDesc: orderByDesc,
      withMetadata: withMetadata,
      excludeZeroValue: excludeZeroValue,
      maxCount: maxCount,
      pageKey: pageKey,
      from: owner,
      addresses: addresses,
    );
  }

  /// [getAssetTransfers] internal function to return all transfers
  /// {@macro transfers}
  Future<TransferResponse> _getAssetTransfers(
      {Uint256? fromBlock,
      Uint256? toBlock,
      EthereumAddress? from,
      EthereumAddress? to,
      bool orderByDesc = false,
      bool withMetadata = false,
      bool excludeZeroValue = false,
      Uint256? maxCount,
      String? pageKey,
      List<TransferCategory>? categories,
      List<EthereumAddress>? addresses}) async {
    final params = {
      "fromBlock": fromBlock?.toHex() ?? "0x${BigInt.zero.toRadixString(16)}",
      "toBlock": toBlock?.toHex() ?? "latest",
      "order": orderByDesc ? "desc" : "asc",
      "withMetadata": withMetadata,
      "excludeZeroValue": excludeZeroValue,
      "maxCount": maxCount?.toHex() ?? "0x3e8",
      "category": categories?.map((e) => e.name).toList(growable: false) ??
          ["external"],
      if (pageKey != null) 'pageKey': pageKey,
      if (addresses != null)
        'contractAddresses':
            addresses.map((e) => e.hex).toList(growable: false),
      if (from != null) 'fromAddress': from.hex else 'toAddress': to!.hex,
    };

    final response = await _provider
        .send<Map<String, dynamic>>('alchemy_getAssetTransfers', [params]);

    final responseType =
        withMetadata ? ResponseType.withMetadata : ResponseType.withoutMetadata;

    return TransferResponse(
      transfers: List<Transfer>.from(
        (response['transfers'] as List<dynamic>).map<Transfer>(
          (x) => Transfer.fromMap(x, responseType),
        ),
      ),
      pageKey:
          response['pageKey'] != null ? response['pageKey'] as String : null,
      responseType: responseType,
    );
  }
}