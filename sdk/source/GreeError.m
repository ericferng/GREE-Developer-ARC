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

#import "GreeError+Internal.h"
#import "GreeGlobalization.h"
#import "AFNetworking.h"
NSString* GreeErrorDomain = @"net.gree.error";

@implementation GreeError
//note that no objects of this type are created

#pragma mark - public interface
+(NSError*)convertToGreeError:(NSError*)input
{
  if([input.domain isEqualToString:GreeAFNetworkingErrorDomain]) {
    NSMutableDictionary* info = [NSMutableDictionary dictionaryWithDictionary:input.userInfo];
    NSString* oldDescription = [input.userInfo objectForKey:NSLocalizedDescriptionKey];
    if(oldDescription) {
      [info setObject:oldDescription forKey:@"AFNetworkingErrorDescription"];
    }
    return [GreeError localizedGreeErrorWithCode:GreeErrorCodeNetworkError userInfo:info];
  }
  if([input.domain isEqualToString:@"JKErrorDomain"]) {
    NSMutableDictionary* info = [NSMutableDictionary dictionaryWithDictionary:input.userInfo];
    NSString* oldDescription = [input.userInfo objectForKey:NSLocalizedDescriptionKey];
    if(oldDescription) {
      [info setObject:oldDescription forKey:@"JSONKitErrorDescription"];
    }
    return [GreeError localizedGreeErrorWithCode:GreeErrorCodeBadDataFromServer userInfo:info];
  }
  return input;
}

#define DEFINELOCALIZATION(code, value) [localizationTable setObject:value forKey:[NSNumber numberWithInteger:code]]
+(NSError*)localizedGreeErrorWithCode:(NSInteger)errorCode userInfo:(NSDictionary*)userInfo
{
  static NSMutableDictionary* localizationTable = nil;
  if(!localizationTable) {
    localizationTable = [[NSMutableDictionary alloc] init];
    DEFINELOCALIZATION(0, GreePlatformString(@"errorHandling.genericError.message", @"An unknown error has occurred."));
    DEFINELOCALIZATION(GreeErrorCodeNetworkError, GreePlatformString(@"errorHandling.genericNetwork.message", @"A network error has occurred."));
    DEFINELOCALIZATION(GreeErrorCodeBadDataFromServer, GreePlatformString(@"errorHandling.badData.message", @"The server returned bad data."));
    DEFINELOCALIZATION(GreeErrorCodeNotAuthorized, GreePlatformString(@"errorHandling.notAuthorized.message", @"Not an authorized user."));
    DEFINELOCALIZATION(GreeErrorCodeAuthorizationFailWithOffline, GreePlatformString(@"errorHandling.authorizationFailWithOffline.message", @"Authorization failed due to offline and grade 0 user enabled."));
    DEFINELOCALIZATION(GreeErrorCodeAuthorizationCancelledByUser, GreePlatformString(@"errorHandling.authorizationCancelledByUser.message", @"Authorization was cancelled by user, since grade 0 user is enabled in this game."));
    DEFINELOCALIZATION(GreeErrorCodeLogoutCancelledByUser, GreePlatformString(@"errorHandling.logoutCancelledByUser.message", @"Logout was cancelled by user"));
    DEFINELOCALIZATION(GreeErrorCodeUserRequired, GreePlatformString(@"errorHandling.userRequired.message", @"A user is required."));
    DEFINELOCALIZATION(GreeWalletPaymentErrorCodeUnknown, GreePlatformString(@"errorHandling.paymentUnknownError.message", @"Payment failed for unknown reason."));
    DEFINELOCALIZATION(GreeWalletPaymentErrorCodeInvalidParameter, GreePlatformString(@"errorHandling.paymentInvalidParameter.message", @"Payment parameter invalid."));
    DEFINELOCALIZATION(GreeWalletPaymentErrorCodeUserCanceled, GreePlatformString(@"errorHandling.paymentCanceled.message", @"Payment canceled by user."));
    DEFINELOCALIZATION(GreeWalletPaymentErrorCodeTransactionExpired, GreePlatformString(@"errorHandling.paymentTransactionExpired.message", @"Payment transaction expired."));
    DEFINELOCALIZATION(GreeWalletPaymentErrorCodeTransactionAlreadyInProgress, GreePlatformString(@"errorHandling.paymentTransactionAlreadyInProgress.message", @"Transaction in progress."));

    DEFINELOCALIZATION(GreeWalletDepositErrorCodeFailedTransactionCommit, GreePlatformString(@"errorHandling.depositTransactionCommitFailed.message", @"Failed to confirm the transaction. Please try again."));
    DEFINELOCALIZATION(GreeWalletDepositErrorCodeTransactionAlreadyInProgress, GreePlatformString(@"errorHandling.depositTransactionAlreadyInProgress.message", @"Please wait for the current transaction to finish."));
    DEFINELOCALIZATION(GreeWalletDepositErrorCodeProductListNotReady, GreePlatformString(@"errorHandling.depositPrefetchProductListNotReady.message", @"The product list has not yet been received."));
    DEFINELOCALIZATION(GreeWalletDepositErrorCodeProductMetadataInvalid, GreePlatformString(@"errorHandling.depositPrefetchMetadataInvalid.message", @"The product metadata is mal-formatted or has an empty product list."));
    DEFINELOCALIZATION(GreeWalletDepositErrorCodeSKProductDataInvalid, GreePlatformString(@"errorHandling.depositPrefetchSKProductDataInvalid.message", @"The skproduct data is invalid."));
    DEFINELOCALIZATION(GreeWalletDepositErrorCodePriceListDataInvalid, GreePlatformString(@"errorHandling.depositPrefetchPriceListDataInvalid.message", @"The price list data is invalid."));
    DEFINELOCALIZATION(GreeWalletDepositErrorCodeSKProductListEmpty, GreePlatformString(@"errorHandling.depositPrefetchSKProductListEmpty.message", @"The skproduct list is empty."));
    DEFINELOCALIZATION(GreeWalletDepositErrorCodeMergedProductListEmpty, GreePlatformString(@"errorHandling.depositPrefetchMergedProductListEmpty.message", @"The final merged product list is empty."));
    DEFINELOCALIZATION(GreeWalletDepositErrorCodeResourceListEmpty, GreePlatformString(@"errorHandling.depositPrefetchResourceListEmpty.message", @"The resource list is empty."));
    DEFINELOCALIZATION(GreeWalletDepositErrorCodeResourceDownloadError, GreePlatformString(@"errorHandling.depositPrefetchResourceDownloadError.message", @"Error happened when downloading resources."));

    DEFINELOCALIZATION(GreeWalletDepositUserStatusError, GreePlatformString(@"wallet.deposit.userstatus.othererror.message", @"An error occurred. Please force quit GREE and start the app again."));
    DEFINELOCALIZATION(GreeWalletBalanceErrorCodeTransactionAlreadyInProgress, GreePlatformString(@"errorHandling.balanceTransactionAlreadyInProgress.message", @"App-specific currency balance query in progress."));
    DEFINELOCALIZATION(GreeWalletBalanceErrorCodeHaveNotBeenInitialized, GreePlatformString(@"errorHandling.balance.balanceHasNotBeenInitialized.message", @"GreeWallet has not been initialized."));
    DEFINELOCALIZATION(GreeWalletPurchaseErrorCodeInvalidProductId, GreePlatformString(@"errorHandling.purchaseInvalidProducId.message", @"That ID does not match any product."));
    DEFINELOCALIZATION(GreeWalletPurchaseErrorCodeUserCancelled, GreePlatformString(@"errorHandling.purchaseUserCancelled.message", @"Cancelled."));
    DEFINELOCALIZATION(GreeWalletUserStatusErrorCodeTransactionAlreadyInProgress, GreePlatformString(@"errorHandling.userStatusTransactionAlreadyInProgress.message", @"Transaction in progress."));
    DEFINELOCALIZATION(GreeWalletUserStatusErrorCodeHaveNotBeenInitialized, GreePlatformString(@"errorHandling.userStatus.userStatusHasNotBeenInitialized.message", @"GreeWallet has not been initialized."));
    DEFINELOCALIZATION(GreeFriendCodeAlreadyRegistered, GreePlatformString(@"errorHandling.friendCodeAlreadyRegistered.message", @"A friend code was already registered."));
    DEFINELOCALIZATION(GreeFriendCodeAlreadyEntered, GreePlatformString(@"errorHandling.friendCodeAlreadyUsed.message", @"The friend code was already used."));
    DEFINELOCALIZATION(GreeFriendCodeNotFound, GreePlatformString(@"errorHandling.missingFriendCode.message", @"No friend code found."));

    DEFINELOCALIZATION(GreeIncentiveSubmitFailed, GreePlatformString(@"errorHandling.incentiveFailureToSubmit.message", @"Submitting incentive failed."));

    DEFINELOCALIZATION(GreeAPINotAllowed, GreePlatformString(@"errorHandling.apiNotAllowed.message", @"API not allowed."));
    DEFINELOCALIZATION(GreeAddressBookNoRecordInDevice, GreePlatformString(@"errorHandling.noAddressBookRecordInDevice.message", @"No address book records in device."));
    DEFINELOCALIZATION(GreeAddressBookNoNeedUpload, GreePlatformString(@"errorHandling.noNeedToUploadAddressBook.message", @"No need to upload address book."));
    DEFINELOCALIZATION(GreeExternalSocialGraphUpdateInvalidParameter, GreePlatformString(@"errorHandling.externalSocialGraphUpdateInvalidParameter.message", @"Invalid parameter specified to update external social graph."));
    DEFINELOCALIZATION(GreeExternalSocialGraphUpdateAccessDenied, GreePlatformString(@"errorHandling.externalSocialGraphUpdateAccessDenied.message", @"Access denied trying to update external social graph."));
    DEFINELOCALIZATION(GreeExternalSocialGraphUpdateOperationFailed, GreePlatformString(@"errorHandling.externalSocialGraphUpdateOperationFailed.message", @"Operation failed trying to update external social graph."));
    DEFINELOCALIZATION(GreeSocialGraphInvalidParameter, GreePlatformString(@"errorHandling.socialGraphParameterInvalid.message", @"Invalid parameter was specified for social graph."));
  }

  NSMutableDictionary* items = [NSMutableDictionary dictionaryWithDictionary:userInfo];
  NSString* localized = [localizationTable objectForKey:[NSNumber numberWithInt:errorCode]];
  if(!localized) {
    localized = [localizationTable objectForKey:[NSNumber numberWithInt:0]];
  }
  [items setObject:localized forKey:NSLocalizedDescriptionKey];
  return [NSError errorWithDomain:GreeErrorDomain code:errorCode userInfo:items];
}

+(NSError*)localizedGreeErrorWithCode:(NSInteger)errorCode
{
  return [GreeError localizedGreeErrorWithCode:errorCode userInfo:nil];
}



@end
