//
// Copyright 2011 GREE, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

/**
 * @file GreeError.h
 * Defines all publicly available error codes.
 */

#import <Foundation/Foundation.h>

/**
 * The NSError domain for all Gree-specific errors
 */
extern NSString* GreeErrorDomain;

enum {
/**
 * @brief A generic message for networking errors.  The request generally can not be fulfilled.
 */
  GreeErrorCodeNetworkError = 1000,
/**
 * @brief Indicates that the server data was not understood; this usually means a networking error.
 */
  GreeErrorCodeBadDataFromServer = 1010,
/**
 * Indicates that the logged in user is not validated by the server.
 * A user type upgrade may be necessary.
 */
  GreeErrorCodeNotAuthorized = 1020,
/**
 * @brief Indicates that the API requires a user and no local user was found.
 */
  GreeErrorCodeUserRequired = 1030,

/**
 * @brief Indicates that the authorization failed when user first launches your app with the internet offline, 
 *        if your app enables grade 0 user.
 * @since 3.2.0
 * @see GreePlatform::authorizeWithBlock:
 */
  GreeErrorCodeAuthorizationFailWithOffline = 1040,
/**
 * @brief Indicates that the authorization is cancelled by the user clicking "No thanks" on authorization pop up window
 * when he/she launches your app, if your app enables grade 0 user.
 * @since 3.2.0
 * @see GreePlatform::authorizeWithBlock:
 */
  GreeErrorCodeAuthorizationCancelledByUser = 1050,
/**
 @brief Indicates that the logout is cancelled by user on authorization pop up window.
 @since 3.2.0
 @see GreePlatform::revokeAuthorizationWithBlock:
 */
  GreeErrorCodeLogoutCancelledByUser = 1060,

  /**
   @ref Shows that a communication error, etc. has occurred in a GreeWallet spending method.
   @see GreeWallet::paymentVerifyWithPaymentId:successBlock:failureBlock:
   */
  GreeWalletPaymentErrorCodeUnknown  = 2000,
  /**
   @ref Shows that the argument specified by a GreeWallet spending method is invalid.
   @see GreeWallet::paymentWithItems:message:callbackUrl:successBlock:failureBlock:
   @see GreeWallet::paymentVerifyWithPaymentId:successBlock:failureBlock:
   */
  GreeWalletPaymentErrorCodeInvalidParameter  = 2010,
  /**
   @ref Shows that a user has made a cancellation on the GreeWallet spending popup.
   */
  GreeWalletPaymentErrorCodeUserCanceled  = 2020,
  /**
   @ref Shows that a transaction on the GreeWallet spending popup has expired.
   */
  GreeWalletPaymentErrorCodeTransactionExpired  = 2030,
  /**
   * @brief Indicates that the current payment request will be ignored because a previous request is still being processed.
   */
  GreeWalletPaymentErrorCodeTransactionAlreadyInProgress  = 2040,

  /**
   * @brief Indicates a transaction which could not be finalized.
   */
  GreeWalletDepositErrorCodeFailedTransactionCommit = 3000,
  /**
   * @brief Indicates that the current purchase request will be ignored because a previous request is still being processed.
   */
  GreeWalletDepositErrorCodeTransactionAlreadyInProgress = 3010,
  /**
   * @brief Indicates a situation where the product list has not yet been received by the client when the request is made.
   */
  GreeWalletDepositErrorCodeProductListNotReady = 3020,
  //#indocBegin "GreeWalletDepositErrorCodeProductMetadataInvalid" en
  /**
   *  Product metadata is mal-formatted or has an empty product list.
   *  @note Product metadata will contain an empty product list if you configured to
   *  use the game’s in-app purchase on GREE Developer Center, but didn’t register any tier.
   */
  //#indocEnd "GreeWalletDepositErrorCodeProductMetadataInvalid" en
  GreeWalletDepositErrorCodeProductMetadataInvalid = 3021,

/**
 * The SKProduct list data from Apple's server is not valid in the following cases:
 * 1. SKProduct has no priceLocale information 
 * 2. SKProduct doesn't have a localizedTitle
 */
  GreeWalletDepositErrorCodeSKProductDataInvalid = 3022,

/**
 * The price list data is mal-formatted or empty:
 * 1. Price list data should be a dictionary but it is not.
 * 2. Price list data is empty.
 */
  GreeWalletDepositErrorCodePriceListDataInvalid = 3023,

/**
 *  The SKProduct list from Apple's server is empty, there are a few possibilities:
 *  1. You didn't register your products on iTunes connect.
 *  2. You registered your products on iTunes connect, but didn't configure your Bundle Identifier correctly in you app.
 */
  GreeWalletDepositErrorCodeSKProductListEmpty = 3024,

/**
 * This error happened when the product id set returned from Apple's server is not matching those registered on Gree's Developer Center.
 */
  GreeWalletDepositErrorCodeMergedProductListEmpty = 3025,

/**
 * Resource list is empty.  
 * @see GreeWalletDepositResourceListDownloader
 * @since 3.3.0
 */
  GreeWalletDepositErrorCodeResourceListEmpty = 3026,

/**
 * An error happened during the process of downloading resources, the 
 * detailed error information is inside error's userInfo.
 * @since 3.3.0
 */
  GreeWalletDepositErrorCodeResourceDownloadError = 3027,

  /**
   * @brief Indicates that the user status could not be determined due to an unexpected error and suggests a restart.
   */
  GreeWalletDepositUserStatusError = 3030,

  /**
   * @brief Indicates that a balance query is already in progress.
   */
  GreeWalletBalanceErrorCodeTransactionAlreadyInProgress  = 3100,
  /**
   * @brief Indicates that GreeWallet has not been initialized.
   * @since 3.4.0
   */
  GreeWalletBalanceErrorCodeHaveNotBeenInitialized = 3110,

/**
 * @brief Indicates that a product id for the requested purchase is invalid.
 */
  GreeWalletPurchaseErrorCodeInvalidProductId  = 3200,
/**
 * @brief Indicates that a user had cancelled the transaction.
 */
  GreeWalletPurchaseErrorCodeUserCancelled = 3210,

  /**
   * @brief Indicates that a user status query is already in progress.
   * @since 3.5.0
   */
  GreeWalletUserStatusErrorCodeTransactionAlreadyInProgress  = 3300,
  /**
   * @brief Indicates that GreeWallet has not been initialized.
   * @since 3.5.0
   */
  GreeWalletUserStatusErrorCodeHaveNotBeenInitialized = 3310,

/**
 * @brief Indicates that this user already has a friend code.
 */
  GreeFriendCodeAlreadyRegistered = 4000,
/**
 * @brief Indicates that this user has already used a friend code.
 */
  GreeFriendCodeAlreadyEntered = 4010,
/**
 * @brief Indicates that no friend code could be found.
 */
  GreeFriendCodeNotFound = 4020,
/**
 * @brief Indicates that the API is not allowed to be called.
 * @since 3.4.0
 */
  GreeAPINotAllowed = 5000,

/**
 * @brief Indicates that there are no address book records are in the device.
 * @since 3.4.0
 */
  GreeAddressBookNoRecordInDevice = 6000,
/**
 * @brief Indicates that address book does not need to be uploaded.
 * @since 3.4.0
 */
  GreeAddressBookNoNeedUpload = 6010,

/**
 * @brief Indicates that invalid parameter was specified to update social graph.
 * @since 3.4.0
 */
  GreeExternalSocialGraphUpdateInvalidParameter = 7000,
/**
 * @brief Indicates that access was denied trying to update external social graph.
 * @since 3.4.0
 */
  GreeExternalSocialGraphUpdateAccessDenied = 7010,
/**
 * @brief Indicates that external social graph update operation has failed.
 * @since 3.4.0
 */
  GreeExternalSocialGraphUpdateOperationFailed = 7020,

/**
 * @brief Indicates that invalid parameter was specified for social graph request.
 * @since 3.4.0
 */
  GreeSocialGraphInvalidParameter = 8000,

/**
 * @brief Indicates that the incentive submit experience a non-network
 * related failure.
 */
  GreeIncentiveSubmitFailed = 9000,

  GreeErrorCodeReservedBase = 100000,
};

