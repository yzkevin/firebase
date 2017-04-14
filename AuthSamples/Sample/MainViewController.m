/*
 * Copyright 2017 Google
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "MainViewController.h"

#import <objc/runtime.h>

#import "FIRAdditionalUserInfo.h"
#import "FIRApp.h"
#import "FIROAuthProvider.h"
#import "FIRPhoneAuthCredential.h"
#import "FIRPhoneAuthProvider.h"
#import "FirebaseAuth.h"
#import "CustomTokenDataEntryViewController.h"
#import "GoogleAuthProvider.h"
#import "SettingsViewController.h"
#import "StaticContentTableViewManager.h"
#import "UIViewController+Alerts.h"
#import "UserInfoViewController.h"
#import "UserTableViewCell.h"

#if INTERNAL_GOOGLE3_BUILD
#import "third_party/objective_c/FirebaseDatabase/FirebaseDatabase.framework/Headers/FirebaseDatabase.h"
#endif

/** @var kTokenGetButtonText
    @brief The text of the "Get Token" button.
 */
static NSString *const kTokenGetButtonText = @"Get Token";

/** @var kTokenRefreshButtonText
    @brief The text of the "Refresh Token" button.
 */
static NSString *const kTokenRefreshButtonText = @"Force Refresh Token";

/** @var kTokenRefreshedAlertTitle
    @brief The title of the "Token Refreshed" alert.
 */
static NSString *const kTokenRefreshedAlertTitle = @"Token";

/** @var kTokenRefreshErrorAlertTitle
    @brief The title of the "Token Refresh error" alert.
 */
static NSString *const kTokenRefreshErrorAlertTitle = @"Get Token Error";

/** @var kSettingsButtonText
    @brief The text of the "Settings" button.
 */
static NSString *const kSettingsButtonText = @"[Sample App Settings]";

/** @var kUserInfoButtonText
    @brief The text of the "Show User Info" button.
 */
static NSString *const kUserInfoButtonText = @"[Show User Info]";

/** @var kSetImageURLText
    @brief The text of the "Set Photo url" button.
 */
static NSString *const kSetPhotoURLText = @"Set Photo url";

/** @var kSignInButtonText
    @brief The text of the "Sign In" button.
 */
static NSString *const kSignInButtonText = @"Sign In (HEADFUL)";

/** @var kSignInGoogleButtonText
    @brief The text of the "Google SignIn" button.
 */
static NSString *const kSignInGoogleButtonText = @"Sign in with Google";

/** @var kSignInAndRetrieveGoogleButtonText
    @brief The text of the "Sign in with Google and retrieve data" button.
 */
static NSString *const kSignInGoogleAndRetrieveDataButtonText =
    @"Sign in with Google and retrieve data";

/** @var kSignInFacebookButtonText
    @brief The text of the "Facebook SignIn" button.
 */
static NSString *const kSignInFacebookButtonText = @"Sign in with Facebook";

/** @var kSignInFacebookAndRetrieveDataButtonText
    @brief The text of the "Facebook SignIn and retrieve data" button.
 */
static NSString *const kSignInFacebookAndRetrieveDataButtonText =
    @"Sign in with Facebook and retrieve data";

/** @var kSignInEmailPasswordButtonText
    @brief The text of the "Email/Password SignIn" button.
 */
static NSString *const kSignInEmailPasswordButtonText = @"Sign in with Email/Password";

/** @var kSignInWithCustomTokenButtonText
    @brief The text of the "Sign In (BYOAuth)" button.
 */
static NSString *const kSignInWithCustomTokenButtonText = @"Sign In (BYOAuth)";

/** @var kSignInAnonymouslyButtonText
    @brief The text of the "Sign In Anonymously" button.
 */
static NSString *const kSignInAnonymouslyButtonText = @"Sign In Anonymously";

/** @var kSignedInAlertTitle
    @brief The text of the "Sign In Succeeded" alert.
 */
static NSString *const kSignedInAlertTitle = @"Signed In";

/** @var kSignInErrorAlertTitle
    @brief The text of the "Sign In Encountered an Error" alert.
 */
static NSString *const kSignInErrorAlertTitle = @"Sign-In Error";

/** @var kSignOutButtonText
    @brief The text of the "Sign Out" button.
 */
static NSString *const kSignOutButtonText = @"Sign Out";

/** @var kDeleteAccountText
    @brief The text of the "Delete Account" button.
 */
static NSString *const kDeleteUserText = @"Delete Account";

/** @var kReauthenticateGoogleText
    @brief The text of the "Reathenticate Google" button.
 */
static NSString *const kReauthenticateGoogleText = @"Reauthenticate Google";

/** @var kReauthenticateGoogleAndRetrieveDataText
    @brief The text of the "Reathenticate Google and retrieve data" button.
 */
static NSString *const kReauthenticateGoogleAndRetrieveDataText =
    @"Reauthenticate Google and retrieve data";

/** @var kReauthenticateFBText
    @brief The text of the "Reathenticate Facebook" button.
 */
static NSString *const kReauthenticateFBText = @"Reauthenticate FB";

/** @var kReauthenticateFBAndRetrieveDataText
    @brief The text of the "Reathenticate Facebook and retrieve data" button.
 */
static NSString *const kReauthenticateFBAndRetrieveDataText =
    @"Reauthenticate FB and retrieve data";

/** @var kReAuthenticateEmail
    @brief The text of the "Reathenticate Email" button.
 */
static NSString *const kReauthenticateEmailText = @"Reauthenticate Email/Password";

/** @var kOKButtonText
    @brief The text of the "OK" button for the Sign In result dialogs.
 */
static NSString *const kOKButtonText = @"OK";

/** @var kSetDisplayNameTitle
    @brief The title of the "Set Display Name" error dialog.
 */
static NSString *const kSetDisplayNameTitle = @"Set Display Name";

/** @var kUpdateEmailText
    @brief The title of the "Update Email" button.
 */
static NSString *const kUpdateEmailText = @"Update Email";

/** @var kUpdatePasswordText
    @brief The title of the "Update Password" button.
 */
static NSString *const kUpdatePasswordText = @"Update Password";

/** @var kUpdatePhoneNumber
    @brief The title of the "Update Photo" button.
 */
static NSString *const kUpdatePhoneNumber = @"Update Phone Number";

/** @var kLinkPhoneNumber
    @brief The title of the "Link phone" button.
 */
static NSString *const kLinkPhoneNumber = @"Link Phone Number";

/** @var kUnlinkPhone
    @brief The title of the "Unlink Phone" button for unlinking phone auth provider.
 */
static NSString *const kUnlinkPhoneNumber = @"Unlink Phone Number";

/** @var kReloadText
    @brief The title of the "Reload User" button.
 */
static NSString *const kReloadText = @"Reload User";

/** @var kLinkWithGoogleText
    @brief The title of the "Link with Google" button.
 */
static NSString *const kLinkWithGoogleText = @"Link with Google";

/** @var kLinkWithGoogleAndRetrieveDataText
    @brief The title of the "Link with Google and retrieve data" button.
 */
static NSString *const kLinkWithGoogleAndRetrieveDataText = @"Link with Google and retrieve data";

/** @var kLinkWithFacebookText
    @brief The title of the "Link with Facebook Account" button.
 */
static NSString *const kLinkWithFacebookText = @"Link with Facebook";

/** @var kLinkWithFacebookAndRetrieveDataText
    @brief The title of the "Link with Facebook and retrieve data" button.
 */
static NSString *const kLinkWithFacebookAndRetrieveDataText =
    @"Link with Facebook and retrieve data";

/** @var kLinkWithEmailPasswordText
    @brief The title of the "Link with Email/Password Account" button.
 */
static NSString *const kLinkWithEmailPasswordText = @"Link with Email/Password";

/** @var kUnlinkTitle
    @brief The text of the "Unlink from Provider" error Dialog.
 */
static NSString *const kUnlinkTitle = @"Unlink from Provider";

/** @var kUnlinkFromGoogle
    @brief The text of the "Unlink from Google" button.
 */
static NSString *const kUnlinkFromGoogle = @"Unlink from Google";

/** @var kUnlinkFromFacebook
    @brief The text of the "Unlink from Facebook" button.
 */
static NSString *const kUnlinkFromFacebook = @"Unlink from Facebook";

/** @var kUnlinkFromEmailPassword
    @brief The text of the "Unlink from Google" button.
 */
static NSString *const kUnlinkFromEmailPassword = @"Unlink from Email/Password";

/** @var kGetProvidersForEmail
    @brief The text of the "Get Provider IDs for Email" button.
 */
static NSString *const kGetProvidersForEmail = @"Get Provider IDs for Email";

/** @var kRequestVerifyEmail
    @brief The text of the "Request Verify Email Link" button.
 */
static NSString *const kRequestVerifyEmail = @"Request Verify Email Link";

/** @var kRequestPasswordReset
    @brief The text of the "Email Password Reset" button.
 */
static NSString *const kRequestPasswordReset = @"Send Password Reset Email";

/** @var kResetPassword
    @brief The text of the "Password Reset" button.
 */
static NSString *const kResetPassword = @"Reset Password";

/** @var kCheckActionCode
    @brief The text of the "Check action code" button.
 */
static NSString *const kCheckActionCode = @"Check action code";

/** @var kApplyActionCode
    @brief The text of the "Apply action code" button.
 */
static NSString *const kApplyActionCode = @"Apply action code";

/** @var kVerifyPasswordResetCode
    @brief The text of the "Verify password reset code" button.
 */
static NSString *const kVerifyPasswordResetCode = @"Verify password reset code";

/** @var kSectionTitleSettings
    @brief The text for the title of the "Settings" section.
 */
static NSString *const kSectionTitleSettings = @"SETTINGS";

/** @var kSectionTitleSignIn
    @brief The text for the title of the "Sign-In" section.
 */
static NSString *const kSectionTitleSignIn = @"SIGN-IN";

/** @var kSectionTitleReauthenticate
    @brief The text for the title of the "Reauthenticate" section.
 */
static NSString *const kSectionTitleReauthenticate = @"REAUTHENTICATE";

/** @var kSectionTitleTokenActions
    @brief The text for the title of the "Token Actions" section.
 */
static NSString *const kSectionTitleTokenActions = @"TOKEN ACTIONS";

/** @var kSectionTitleEditUser
    @brief The text for the title of the "Edit User" section.
 */
static NSString *const kSectionTitleEditUser = @"EDIT USER";

/** @var kSectionTitleLinkUnlinkAccount
    @brief The text for the title of the "Link/Unlink account" section.
 */
static NSString *const kSectionTitleLinkUnlinkAccounts = @"LINK/UNLINK ACCOUNT";

/** @var kSectionTitleUserActions
    @brief The text for the title of the "User Actions" section.
 */
static NSString *const kSectionTitleUserActions = @"USER ACTIONS";

/** @var kSectionTitleUserDetails
    @brief The text for the title of the "User Details" section.
 */
static NSString *const kSectionTitleUserDetails = @"SIGNED-IN USER DETAILS";

/** @var kSectionTitleListeners
    @brief The title for the table view section dedicated to auth state did change listeners.
 */
static NSString *const kSectionTitleListeners = @"Auth State Change Listeners";

/** @var kAddListenerTitle
    @brief The title for the tabke view row which adds a block to the auth state did change
        listeners.
 */
static NSString *const kAddListenerTitle = @"Add";

/** @var kRemoveListenerTitle
    @brief The title for the tabke view row which removes a block to the auth state did change
        listeners.
 */
static NSString *const kRemoveListenerTitle = @"Remove Last";

/** @var kSectionTitleApp
    @brief The text for the title of the "App" section.
 */
static NSString *const kSectionTitleApp = @"APP";

/** @var kCreateUserTitle
    @brief The text of the "Create User" button.
 */
static NSString *const kCreateUserTitle = @"Create User";

/** @var kDeleteAppTitle
    @brief The text of the "Delete App" button.
 */
static NSString *const kDeleteAppTitle = @"Delete App";

/** @var kSectionTitleManualTests
    @brief The section title for automated manual tests.
 */
static NSString *const kSectionTitleManualTests = @"Manual Tests";

/** @var kAutoBYOAuthTitle
    @brief The button title for automated BYOAuth operation.
 */
static NSString *const kAutoBYOAuthTitle = @"BYOAuth";

/** @var kAutoSignInGoogle
    @brief The button title for automated Google sign-in operation.
 */
static NSString *const kAutoSignInGoogle = @"Sign In With Google";

/** @var kAutoSignInFacebook
    @brief The button title for automated Facebook sign-in operation.
 */
static NSString *const kAutoSignInFacebook = @"Sign In With Facebook";

/** @var kAutoSignUpEmailPassword
    @brief The button title for automated sign-up with email/password.
 */
static NSString *const kAutoSignUpEmailPassword = @"Sign Up With Email/Password";

/** @var kAutoSignInAnonymously
    @brief The button title for automated sign-in anonymously.
 */
static NSString *const kAutoSignInAnonymously = @"Sign In Anonymously";

/** @var kAutoAccountLinking
    @brief The button title for automated account linking.
 */
static NSString *const kAutoAccountLinking = @"Link with Google";

/** @var kGitHubSignInButtonText
    @brief The button title for signing in with github.
 */
static NSString *const kGitHubSignInButtonText = @"Sign In with GitHub";

/** @var kExpiredCustomTokenUrl
    @brief The url for obtaining a valid custom token string used to test BYOAuth.
 */
static NSString *const kCustomTokenUrl = @"https://fb-sa-1211.appspot.com/token";

/** @var kCustomTokenUrl
    @brief The url for obtaining an expired custom token string used to test BYOAuth.
 */
static NSString *const kExpiredCustomTokenUrl = @"https://fb-sa-1211.appspot.com/expired_token";

/** @var kFakeDisplayPhotoUrl
    @brief The url for obtaining a display displayPhoto used for testing.
 */
static NSString *const kFakeDisplayPhotoUrl =
    @"https://www.gstatic.com/images/branding/product/1x/play_apps_48dp.png";

/** @var kFakeDisplayName
    @brief Fake display name for testing.
 */
static NSString *const kFakeDisplayName = @"John GoogleSpeed";

/** @var kFakeEmail
    @brief Fake email for testing.
 */
static NSString *const kFakeEmail =@"firemail@example.com";

/** @var kFakePassword
    @brief Fake password for testing.
 */
static NSString *const kFakePassword =@"fakePassword";

/** @var kInvalidCustomToken
    @brief The custom token string for testing BYOAuth.
 */
static NSString *const kInvalidCustomToken = @"invalid custom token.";

/** @var kSafariGoogleSignOutMessagePrompt
    @brief The message text informing user to sign-out from Google on safari before continuing.
 */
static NSString *const kSafariGoogleSignOutMessagePrompt = @"This automated test assumes that no "
    "Google account is signed in on Safari, if your are not prompted for a password, sign out on "
    "Safari and rerun the test.";

/** @var kSafariFacebookSignOutMessagePrompt
    @brief The message text informing user to sign-out from Facebook on safari before continuing.
 */
static NSString *const kSafariFacebookSignOutMessagePrompt = @"This automated test assumes that no "
    "Facebook account is signed in on Safari, if your are not prompted for a password, sign out on "
    "Safari and rerun the test.";

/** @var kUnlinkAccountMessagePrompt
    @brief The message text informing user to use an unlinked account for account linking.
 */
static NSString *const kUnlinkAccountMessagePrompt = @"Sign into gmail with an email address "
    "that has not been linked to this sample application before. Delete account if necessary.";

// Declared extern in .h file.
NSString *const kCreateUserAccessibilityID = @"CreateUserAccessibilityID";

/** @var kPhoneAuthSectionTitle
    @brief The title for the phone auth section of the test app.
 */
static NSString *const kPhoneAuthSectionTitle = @"Phone Auth";

/** @var kPhoneNumberSignInTitle
    @brief The title for button to sign in with phone number.
 */
static NSString *const kPhoneNumberSignInTitle = @"Sign in With Phone Number";

/** @typedef showEmailPasswordDialogCompletion
    @brief The type of block which gets called to complete the Email/Password dialog flow.
 */
typedef void (^ShowEmailPasswordDialogCompletion)(FIRAuthCredential *credential);

/** @typedef FIRTokenCallback
    @brief The type of block which gets called when a token is ready.
 */
typedef void (^FIRTokenCallback)(NSString *_Nullable token, NSError *_Nullable error);

/** @brief Method declarations copied from FIRAppInternal.h to avoid importing non-public headers.
 */
@interface FIRApp (Internal)
/** @fn getTokenForcingRefresh:withCallback:
    @brief Retrieves the Firebase authentication token, possibly refreshing it.
    @param forceRefresh Forces a token refresh. Useful if the token becomes invalid for some reason
        other than an expiration.
    @param callback The block to invoke when the token is available.
 */
- (void)getTokenForcingRefresh:(BOOL)forceRefresh withCallback:(nonnull FIRTokenCallback)callback;
@end

@implementation MainViewController {
  NSMutableString *_consoleString;

  /** @var _authStateDidChangeListeners
      @brief An array of handles created during calls to @c FIRAuth.addAuthStateDidChangeListener:
   */
  NSMutableArray<FIRAuthStateDidChangeListenerHandle> *_authStateDidChangeListeners;

  /** @var _userInMemory
      @brief Acts like the "memory" function of a calculator. An operation allows sample app users
          to assign this value based on @c FIRAuth.currentUser or clear this value.
   */
  FIRUser *_userInMemory;

  /** @var _useUserInMemory
      @brief Instructs the application to use _userInMemory instead of @c FIRAuth.currentUser for
          testing operations. This allows us to test if things still work with a user who is not
          the @c FIRAuth.currentUser, and also allows us to test those things while
          @c FIRAuth.currentUser remains nil (after a sign-out) and also when @c FIRAuth.currentUser
          is non-nil (do to a subsequent sign-in.)
   */
  BOOL _useUserInMemory;
}

/** @fn initWithNibName:bundle:
    @brief Overridden default initializer.
 */
- (id)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    _authStateDidChangeListeners = [NSMutableArray array];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(authStateChangedForAuth:)
                                                 name:FIRAuthStateDidChangeNotification
                                               object:nil];
    self.useStatusBarSpinner = YES;
#if INTERNAL_GOOGLE3_BUILD
    // TODO:(zsika) Remove and add option to include database or not.
    [[FIRDatabase database] reference];
#endif
  }
  return self;
}

- (void)viewDidLoad {
  // Give us a circle for the image view:
  _userInfoTableViewCell.userInfoProfileURLImageView.layer.cornerRadius =
      _userInfoTableViewCell.userInfoProfileURLImageView.frame.size.width / 2.0f;
  _userInfoTableViewCell.userInfoProfileURLImageView.layer.masksToBounds = YES;
  _userInMemoryInfoTableViewCell.userInfoProfileURLImageView.layer.cornerRadius =
      _userInMemoryInfoTableViewCell.userInfoProfileURLImageView.frame.size.width / 2.0f;
  _userInMemoryInfoTableViewCell.userInfoProfileURLImageView.layer.masksToBounds = YES;
  [self updateTable];
  [self updateUserInfo];
}

- (void)updateTable {
  __weak typeof(self) weakSelf = self;
  _tableViewManager.contents =
    [StaticContentTableViewContent contentWithSections:@[
      [StaticContentTableViewSection sectionWithTitle:kSectionTitleUserDetails cells:@[
        [StaticContentTableViewCell cellWithCustomCell:_userInfoTableViewCell action:^{
          [weakSelf presentUserInfo];
        }],
        [StaticContentTableViewCell cellWithCustomCell:_userToUseCell],
        [StaticContentTableViewCell cellWithCustomCell:_userInMemoryInfoTableViewCell action:^{
          [weakSelf presentUserInMemoryInfo];
        }],
      ]],
      [StaticContentTableViewSection sectionWithTitle:kSectionTitleSettings cells:@[
        [StaticContentTableViewCell cellWithTitle:kSettingsButtonText
                                           action:^{ [weakSelf presentSettings]; }]
      ]],
      [StaticContentTableViewSection sectionWithTitle:kPhoneAuthSectionTitle cells:@[
        [StaticContentTableViewCell cellWithTitle:kPhoneNumberSignInTitle
                                           action:^{ [weakSelf signInWithPhoneNumber]; }],
        [StaticContentTableViewCell cellWithTitle:kUpdatePhoneNumber
                                           action:^{ [weakSelf updatePhoneNumber]; }],
        [StaticContentTableViewCell cellWithTitle:kLinkPhoneNumber
                                           action:^{ [weakSelf linkPhoneNumber]; }],
        [StaticContentTableViewCell cellWithTitle:kUnlinkPhoneNumber
                                           action:^{
          [weakSelf unlinkFromProvider:FIRPhoneAuthProviderID];
        }],
      ]],
      [StaticContentTableViewSection sectionWithTitle:kSectionTitleSignIn cells:@[
        [StaticContentTableViewCell cellWithTitle:kCreateUserTitle
                                            value:nil
                                           action:^{ [weakSelf createUser]; }
                                  accessibilityID:kCreateUserAccessibilityID],
        [StaticContentTableViewCell cellWithTitle:kSignInGoogleButtonText
                                           action:^{ [weakSelf signInGoogle]; }],
        [StaticContentTableViewCell cellWithTitle:kSignInGoogleAndRetrieveDataButtonText
                                           action:^{ [weakSelf signInGoogleAndRetrieveData]; }],
        [StaticContentTableViewCell cellWithTitle:kSignInFacebookButtonText
                                           action:^{ [weakSelf signInFacebook]; }],
        [StaticContentTableViewCell cellWithTitle:kSignInFacebookAndRetrieveDataButtonText
                                           action:^{ [weakSelf signInFacebookAndRetrieveData]; }],
        [StaticContentTableViewCell cellWithTitle:kSignInEmailPasswordButtonText
                                           action:^{ [weakSelf signInEmailPassword]; }],
        [StaticContentTableViewCell cellWithTitle:kSignInWithCustomTokenButtonText
                                           action:^{ [weakSelf signInWithCustomToken]; }],
        [StaticContentTableViewCell cellWithTitle:kSignInAnonymouslyButtonText
                                           action:^{ [weakSelf signInAnonymously]; }],
        [StaticContentTableViewCell cellWithTitle:kGitHubSignInButtonText
                                           action:^{ [weakSelf signInWithGitHub]; }],
        [StaticContentTableViewCell cellWithTitle:kSignOutButtonText
                                           action:^{ [weakSelf signOut]; }]
      ]],
      [StaticContentTableViewSection sectionWithTitle:kSectionTitleUserActions cells:@[
        [StaticContentTableViewCell cellWithTitle:kSetDisplayNameTitle
                                           action:^{ [weakSelf setDisplayName]; }],
        [StaticContentTableViewCell cellWithTitle:kSetPhotoURLText
                                           action:^{ [weakSelf setPhotoURL]; }],
        [StaticContentTableViewCell cellWithTitle:kReloadText
                                           action:^{ [weakSelf reloadUser]; }],
        [StaticContentTableViewCell cellWithTitle:kGetProvidersForEmail
                                           action:^{ [weakSelf getProvidersForEmail]; }],
        [StaticContentTableViewCell cellWithTitle:kRequestVerifyEmail
                                           action:^{ [weakSelf requestVerifyEmail]; }],
        [StaticContentTableViewCell cellWithTitle:kRequestPasswordReset
                                           action:^{ [weakSelf requestPasswordReset]; }],
        [StaticContentTableViewCell cellWithTitle:kResetPassword
                                           action:^{ [weakSelf resetPassword]; }],
        [StaticContentTableViewCell cellWithTitle:kCheckActionCode
                                           action:^{ [weakSelf checkActionCode]; }],
        [StaticContentTableViewCell cellWithTitle:kApplyActionCode
                                           action:^{ [weakSelf applyActionCode]; }],
        [StaticContentTableViewCell cellWithTitle:kVerifyPasswordResetCode
                                           action:^{ [weakSelf verifyPasswordResetCode]; }],
        [StaticContentTableViewCell cellWithTitle:kUpdateEmailText
                                           action:^{ [weakSelf updateEmail]; }],
        [StaticContentTableViewCell cellWithTitle:kUpdatePasswordText
                                           action:^{ [weakSelf updatePassword]; }],
        [StaticContentTableViewCell cellWithTitle:kDeleteUserText
                                           action:^{ [weakSelf deleteAccount]; }],
      ]],
      [StaticContentTableViewSection sectionWithTitle:kSectionTitleReauthenticate cells:@[
        [StaticContentTableViewCell cellWithTitle:kReauthenticateGoogleText
                                           action:^{ [weakSelf reauthenticateGoogle]; }],
        [StaticContentTableViewCell
            cellWithTitle:kReauthenticateGoogleAndRetrieveDataText
                   action:^{ [weakSelf reauthenticateGoogleAndRetrieveData]; }],
        [StaticContentTableViewCell cellWithTitle:kReauthenticateFBText
                                           action:^{ [weakSelf reauthenticateFB]; }],
        [StaticContentTableViewCell cellWithTitle:kReauthenticateFBAndRetrieveDataText
                                           action:^{ [weakSelf reauthenticateFBAndRetrieveData]; }],
        [StaticContentTableViewCell cellWithTitle:kReauthenticateEmailText
                                           action:^{ [weakSelf reauthenticateEmailPassword]; }]
      ]],
      [StaticContentTableViewSection sectionWithTitle:kSectionTitleTokenActions cells:@[
        [StaticContentTableViewCell cellWithTitle:kTokenGetButtonText
                                           action:^{ [weakSelf getUserTokenWithForce:NO]; }],
        [StaticContentTableViewCell cellWithTitle:kTokenRefreshButtonText
                                           action:^{ [weakSelf getUserTokenWithForce:YES]; }]
      ]],
      [StaticContentTableViewSection sectionWithTitle:kSectionTitleLinkUnlinkAccounts cells:@[
        [StaticContentTableViewCell cellWithTitle:kLinkWithGoogleText
                                           action:^{ [weakSelf linkWithGoogle]; }],
        [StaticContentTableViewCell cellWithTitle:kLinkWithGoogleAndRetrieveDataText
                                           action:^{ [weakSelf linkWithGoogleAndRetrieveData]; }],
        [StaticContentTableViewCell cellWithTitle:kLinkWithFacebookText
                                           action:^{ [weakSelf linkWithFacebook]; }],
        [StaticContentTableViewCell cellWithTitle:kLinkWithFacebookAndRetrieveDataText
                                           action:^{ [weakSelf linkWithFacebookAndRetrieveData]; }],
        [StaticContentTableViewCell cellWithTitle:kLinkWithEmailPasswordText
                                           action:^{ [weakSelf linkWithEmailPassword]; }],
        [StaticContentTableViewCell cellWithTitle:kUnlinkFromGoogle
                                           action:^{
          [weakSelf unlinkFromProvider:FIRGoogleAuthProviderID];
        }],
        [StaticContentTableViewCell cellWithTitle:kUnlinkFromFacebook
                                           action:^{
          [weakSelf unlinkFromProvider:FIRFacebookAuthProviderID];
        }],
        [StaticContentTableViewCell cellWithTitle:kUnlinkFromEmailPassword
                                           action:^{
          [weakSelf unlinkFromProvider:FIREmailPasswordAuthProviderID];
        }]
      ]],
      [StaticContentTableViewSection sectionWithTitle:kSectionTitleApp cells:@[
        [StaticContentTableViewCell cellWithTitle:kDeleteAppTitle
                                           action:^{ [weakSelf deleteApp]; }],
        [StaticContentTableViewCell cellWithTitle:kTokenGetButtonText
                                           action:^{ [weakSelf getAppTokenWithForce:NO]; }],
        [StaticContentTableViewCell cellWithTitle:kTokenRefreshButtonText
                                           action:^{ [weakSelf getAppTokenWithForce:YES]; }]
      ]],
      [StaticContentTableViewSection sectionWithTitle:kSectionTitleListeners cells:@[
        [StaticContentTableViewCell cellWithTitle:kAddListenerTitle
                                           action:^{ [weakSelf addListener]; }],
        [StaticContentTableViewCell cellWithTitle:kRemoveListenerTitle
                                           action:^{ [weakSelf removeListener]; }],
      ]],
      [StaticContentTableViewSection sectionWithTitle:kSectionTitleManualTests cells:@[
        [StaticContentTableViewCell cellWithTitle:kAutoBYOAuthTitle
                                           action:^{ [weakSelf automatedBYOAuth]; }],
        [StaticContentTableViewCell cellWithTitle:kAutoSignInGoogle
                                           action:^{ [weakSelf automatedSignInGoogle]; }],
        [StaticContentTableViewCell cellWithTitle:kAutoSignInFacebook
                                           action:^{ [weakSelf automatedSignInFacebook]; }],
        [StaticContentTableViewCell cellWithTitle:kAutoSignUpEmailPassword
                                           action:^{ [weakSelf automatedEmailSignUp]; }],
        [StaticContentTableViewCell cellWithTitle:kAutoSignInAnonymously
                                           action:^{ [weakSelf automatedAnonymousSignIn]; }],
        [StaticContentTableViewCell cellWithTitle:kAutoAccountLinking
                                           action:^{ [weakSelf automatedAccountLinking]; }]
      ]]
    ]];
}

#pragma mark - Interface Builder Actions

- (IBAction)userToUseDidChange:(UISegmentedControl *)sender {
  _useUserInMemory = (sender.selectedSegmentIndex == 1);
}

- (IBAction)memoryPlus {
  _userInMemory = [FIRAuth auth].currentUser;
  [self updateUserInfo];
}

- (IBAction)memoryClear {
  _userInMemory = nil;
  [self updateUserInfo];
}

#pragma mark - Actions

/** @fn signInWithProvider:provider:
    @brief Perform sign in with credential operataion, for given auth provider.
    @provider The auth provider.
    @callback The callback to continue the flow which executed this sign-in.
 */
- (void)signInWithProvider:(nonnull id<AuthProvider>)provider callback:(void(^)(void))callback {
  if (!provider) {
    [self logFailedTest:@"A valid auth provider was not provided to the signInWithProvider."];
    return;
  }
  [provider getAuthCredentialWithPresentingViewController:self
                                                 callback:^(FIRAuthCredential *credential,
                                                            NSError *error) {
    if (!credential) {
      [self logFailedTest:@"The test needs a valid credential to continue."];
      return;
    }
    [[FIRAuth auth] signInWithCredential:credential completion:^(FIRUser *_Nullable user,
                                                                 NSError *_Nullable error) {
      if (error) {
        [self logFailure:@"sign-in with provider failed" error:error];
        [self logFailedTest:@"Sign-in should succeed"];
        return;
      } else {
        [self logSuccess:@"sign-in with provider succeeded."];
        callback();
      }
    }];
  }];
}

/** @fn automatedSignInGoogle
    @brief Automatically executes the manual test for sign-in with Google.
 */
- (void)automatedSignInGoogle {
  [self showMessagePromptWithTitle:kAutoSignInGoogle
                           message:kSafariGoogleSignOutMessagePrompt
                  showCancelButton:NO
                        completion:^(BOOL userPressedOK, NSString *_Nullable userInput) {
    FIRAuth *auth = [FIRAuth auth];
    if (!auth) {
      [self logFailedTest:@"Could not obtain auth object."];
      return;
    }
    #warning TODO(zsika) Test should check for sign out errors.
    [auth signOut:NULL];
    [self log:@"INITIATING AUTOMATED MANUAL TEST FOR GOOGLE SIGN IN:"];
    [self signInWithProvider:[AuthProviders google] callback:^{
      [self logSuccess:@"sign-in with Google provider succeeded."];
      #warning TODO(zsika) Test should check for sign out errors.
      [auth signOut:NULL];
      [self signInWithProvider:[AuthProviders google] callback:^{
        [self logSuccess:@"sign-in with Google provider succeeded."];
        [self updateEmailPasswordWithCompletion:^{
          [self automatedSignInGoogleDisplayNamePhotoURL];
        }];
      }];
    }];
  }];
}

/** @fn automatedSignInGoogleDisplayNamePhotoURL
    @brief Automatically executes the manual test for setting email and password for sign in with
        Google.
 */
- (void)automatedSignInGoogleDisplayNamePhotoURL {
  [self signInWithProvider:[AuthProviders google] callback:^{
    [self updateDisplayNameAndPhotoURlWithCompletion:^{
      [self log:@"FINISHED AUTOMATED MANUAL TEST FOR SIGN-IN WITH GOOGlE."];
      [self reloadUser];
    }];
  }];
}

/** @fn automatedSignInFacebook
    @brief Automatically executes the manual test for sign-in with Facebook.
 */
- (void)automatedSignInFacebook {
  [self showMessagePromptWithTitle:kAutoSignInFacebook
                           message:kSafariFacebookSignOutMessagePrompt
                  showCancelButton:NO
                        completion:^(BOOL userPressedOK, NSString *_Nullable userInput) {
    FIRAuth *auth = [FIRAuth auth];
    if (!auth) {
      [self logFailedTest:@"Could not obtain auth object."];
      return;
    }
    #warning TODO(zsika) Test should check for sign out errors.
    [auth signOut:NULL];
    [self log:@"INITIATING AUTOMATED MANUAL TEST FOR FACEBOOK SIGN IN:"];
    [self signInWithProvider:[AuthProviders facebook] callback:^{
      [self logSuccess:@"sign-in with Facebook provider succeeded."];
      #warning TODO(zsika) Test should check for sign out errors.
      [auth signOut:NULL];
      [self signInWithProvider:[AuthProviders facebook] callback:^{
        [self logSuccess:@"sign-in with Facebook provider succeeded."];
        [self updateEmailPasswordWithCompletion:^{
          [self automatedSignInFacebookDisplayNamePhotoURL];
        }];
      }];
    }];
  }];
}

/** @fn automatedEmailSignUp
    @brief Automatically executes the manual test for sign-up with email/password.
 */
- (void)automatedEmailSignUp {
  [self log:@"INITIATING AUTOMATED MANUAL TEST FOR FACEBOOK SIGN IN:"];
  FIRAuth *auth = [FIRAuth auth];
  if (!auth) {
    [self logFailedTest:@"Could not obtain auth object."];
    return;
  }
  [self signUpNewEmail:kFakeEmail password:kFakePassword callback:^(FIRUser *_Nullable user,
                                                                    NSError *_Nullable error) {
    if (error) {
      [self logFailedTest: @" Email/Password Account account creation failed"];
      return;
    }
    #warning TODO(zsika) Test should check for sign out errors.
    [auth signOut:NULL];
    FIRAuthCredential *credential =
        [FIREmailPasswordAuthProvider credentialWithEmail:kFakeEmail
                                                 password:kFakePassword];
    [auth signInWithCredential:credential
                     completion:^(FIRUser *_Nullable user,
                                  NSError *_Nullable error) {
      if (error) {
        [self logFailure:@"sign-in with Email/Password failed" error:error];
        [self logFailedTest:@"sign-in with Email/Password should succeed."];
        return;
      }
      [self logSuccess:@"sign-in with Email/Password succeeded."];
      [self log:@"FINISHED AUTOMATED MANUAL TEST FOR SIGN-IN WITH EMAIL/PASSWORD."];
      // Delete the user so that we can reuse the fake email address for subsequent tests.
      [auth.currentUser deleteWithCompletion:^(NSError *_Nullable error) {
        if (error) {
          [self logFailure:@"Failed to delete user" error:error];
          [self logFailedTest:@"Deleting a user that was recently signed-in should succeed."];
          return;
        }
        [self logSuccess:@"User deleted."];
      }];
    }];
  }];
}

/** @fn automatedAnonymousSignIn
    @brief Automatically executes the manual test for sign-in anonymously.
 */
- (void)automatedAnonymousSignIn {
  [self log:@"INITIATING AUTOMATED MANUAL TEST FOR ANONYMOUS SIGN IN:"];
  FIRAuth *auth = [FIRAuth auth];
  if (!auth) {
    [self logFailedTest:@"Could not obtain auth object."];
    return;
  }
  #warning TODO(zsika) Test should check for sign out errors.
  [auth signOut:NULL];
  [self signInAnonymouslyWithCallback:^(FIRUser *_Nullable user, NSError *_Nullable error) {
    if (user) {
      NSString *anonymousUID = user.uid;
      [self signInAnonymouslyWithCallback:^(FIRUser *_Nullable user, NSError *_Nullable error) {
        if (![user.uid isEqual:anonymousUID]) {
          [self logFailedTest:@"Consecutive anonymous sign-ins should yeild the same User ID"];
          return;
        }
        [self log:@"FINISHED AUTOMATED MANUAL TEST FOR ANONYMOUS SIGN IN."];
      }];
    }
    #warning TODO(zsika) What should happen in the "else" for "if (user) { ... }" ?
  }];
}

/** @fn signInAnonymouslyWithCallback:
    @brief Performs anonymous sign in and then executes callback.
    @param callback The callback to be executed.
 */
- (void)signInAnonymouslyWithCallback:(nullable FIRAuthResultCallback)callback {
  FIRAuth *auth = [FIRAuth auth];
  if (!auth) {
    [self logFailedTest:@"Could not obtain auth object."];
    return;
  }
  [auth signInAnonymouslyWithCompletion:^(FIRUser *_Nullable user,
                                          NSError *_Nullable error) {
    if (error) {
      [self logFailure:@"sign-in anonymously failed" error:error];
      [self logFailedTest:@"Recently signed out user should be able to sign in anonymously."];
      return;
    }
    [self logSuccess:@"sign-in anonymously succeeded."];
    if (callback) {
      callback(user, nil);
    }
  }];
}

/** @fn automatedAccountLinking
    @brief Automatically executes the manual test for account linking.
 */
- (void)automatedAccountLinking {
  [self log:@"INITIATING AUTOMATED MANUAL TEST FOR ACCOUNT LINKING:"];
  FIRAuth *auth = [FIRAuth auth];
  if (!auth) {
    [self logFailedTest:@"Could not obtain auth object."];
    return;
  }
  #warning TODO(zsika) Test should check for sign out errors.
  [auth signOut:NULL];
  [self signInAnonymouslyWithCallback:^(FIRUser *_Nullable user, NSError *_Nullable error) {
    if (user) {
      NSString *anonymousUID = user.uid;
      [self showMessagePromptWithTitle:@"Sign In Instructions"
                               message:kUnlinkAccountMessagePrompt
                      showCancelButton:NO
                            completion:^(BOOL userPressedOK, NSString *_Nullable userInput) {
        [[AuthProviders google]
            getAuthCredentialWithPresentingViewController:self
                                                 callback:^(FIRAuthCredential *credential,
                                                            NSError *error) {
          if (credential) {
            [user linkWithCredential:credential completion:^(FIRUser *user, NSError *error) {
              if (error) {
                [self logFailure:@"link auth provider failed" error:error];
                [self logFailedTest:@"Account needs to be linked to complete the test."];
                return;
              }
              [self logSuccess:@"link auth provider succeeded."];
              if (user.isAnonymous) {
                [self logFailure:@"link auth provider failed, user still anonymous" error:error];
                [self logFailedTest:@"Account needs to be linked to complete the test."];
              }
              if (![user.uid isEqual:anonymousUID]){
                [self logFailedTest:@"link auth provider failed, UID's are different. Make sure "
                    "you link an account that has NOT been Linked nor Signed-In before."];
                return;
              }
              [self log:@"FINISHED AUTOMATED MANUAL TEST FOR ACCOUNT LINKING."];
            }];
          }
       }];
     }];
    }
  }];
}

/** @fn automatedSignInFacebookDisplayNamePhotoURL
    @brief Automatically executes the manual test for setting email and password for sign-in with
        Facebook.
 */
- (void)automatedSignInFacebookDisplayNamePhotoURL {
  [self signInWithProvider:[AuthProviders facebook] callback:^{
    [self updateDisplayNameAndPhotoURlWithCompletion:^{
      [self log:@"FINISHED AUTOMATED MANUAL TEST FOR SIGN-IN WITH FACEBOOK."];
      [self reloadUser];
    }];
  }];
}

/** @fn automatedBYOauth
    @brief Automatically executes the manual test for BYOAuth.
 */
- (void)automatedBYOAuth {
  [self log:@"INITIATING AUTOMATED MANUAL TEST FOR BYOAUTH:"];
  [self showSpinner:^{
    NSError *error;
    NSString *customToken = [NSString stringWithContentsOfURL:[NSURL URLWithString:kCustomTokenUrl]
                                                     encoding:NSUTF8StringEncoding
                                                        error:&error];
    NSString *expiredCustomToken =
      [NSString stringWithContentsOfURL:[NSURL URLWithString:kExpiredCustomTokenUrl]
                               encoding:NSUTF8StringEncoding
                                  error:&error];
    [self hideSpinner:^{
      if (error) {
        [self log:@"There was an error retrieving the custom token."];
        return;
      }
      FIRAuth *auth = [FIRAuth auth];
      [auth signInWithCustomToken:customToken
                       completion:^(FIRUser *_Nullable user, NSError *_Nullable error) {
        if (error) {
          [self logFailure:@"sign-in with custom token failed" error:error];
          [self logFailedTest:@"A fresh custom token should succeed in signing-in."];
          return;
        }
        [self logSuccess:@"sign-in with custom token succeeded."];
        [auth.currentUser getTokenForcingRefresh:NO
                                       completion:^(NSString *_Nullable token,
                                                    NSError *_Nullable error) {
          if (error) {
            [self logFailure:@"refresh token failed" error:error];
            [self logFailedTest:@"Refresh token should be available."];
            return;
          }
          [self logSuccess:@"refresh token succeeded."];
          #warning TODO(zsika) Test should check for sign out errors.
          [auth signOut:NULL];
          [auth signInWithCustomToken:expiredCustomToken
                           completion:^(FIRUser *_Nullable user, NSError *_Nullable error) {
            if (!error) {
              [self logSuccess:@"sign-in with custom token succeeded."];
              [self logFailedTest:@"sign-in with an expired custom token should NOT succeed."];
              return;
            }
            [self logFailure:@"sign-in with custom token failed" error:error];
            [auth signInWithCustomToken:kInvalidCustomToken
                             completion:^(FIRUser *_Nullable user,
                                          NSError *_Nullable error) {
              if (!error) {
                [self logSuccess:@"sign-in with custom token succeeded."];
                [self logFailedTest:@"sign-in with an invalid custom token should NOT succeed."];
                return;
              }
              [self logFailure:@"sign-in with custom token failed" error:error];
              //next step of automated test.
              [self automatedBYOAuthEmailPassword];
            }];
          }];
        }];
      }];
    }];
  }];
}

/** @fn automatedBYOAuthEmailPassword
    @brief Automatically executes the manual test for setting email and password in BYOAuth.
 */
- (void)automatedBYOAuthEmailPassword {
  [self showSpinner:^{
    NSError *error;
    NSString *customToken = [NSString stringWithContentsOfURL:[NSURL URLWithString:kCustomTokenUrl]
                                                     encoding:NSUTF8StringEncoding
                                                        error:&error];
    [self hideSpinner:^{
      if (error) {
        [self log:@"There was an error retrieving the custom token."];
        return;
      }
      [[FIRAuth auth] signInWithCustomToken:customToken
                                 completion:^(FIRUser *_Nullable user, NSError *_Nullable error) {
        if (error) {
          [self logFailure:@"sign-in with custom token failed" error:error];
          [self logFailedTest:@"A fresh custom token should succeed in signing-in."];
          return;
        }
        [self logSuccess:@"sign-in with custom token succeeded."];
        [self updateEmailPasswordWithCompletion:^{
          [self automatedBYOAuthDisplayNameAndPhotoURl];
        }];
      }];
    }];
  }];
}

/** @fn automatedBYOAuthDisplayNameAndPhotoURl
    @brief Automatically executes the manual test for setting display name and photo url in BYOAuth.
 */
- (void)automatedBYOAuthDisplayNameAndPhotoURl {
  [self showSpinner:^{
    NSError *error;
    NSString *customToken = [NSString stringWithContentsOfURL:[NSURL URLWithString:kCustomTokenUrl]
                                                     encoding:NSUTF8StringEncoding
                                                        error:&error];
    [self hideSpinner:^{
      if (error) {
        [self log:@"There was an error retrieving the custom token."];
        return;
      }
      [[FIRAuth auth] signInWithCustomToken:customToken
                                 completion:^(FIRUser *_Nullable user, NSError *_Nullable error) {
        if (error) {
          [self logFailure:@"sign-in with custom token failed" error:error];
          [self logFailedTest:@"A fresh custom token should succeed in signing-in."];
          return;
        }
        [self logSuccess:@"sign-in with custom token succeeded."];
        [self updateDisplayNameAndPhotoURlWithCompletion:^{
          [self log:@"FINISHED AUTOMATED MANUAL TEST FOR BYOAUTH."];
          [self reloadUser];
        }];
      }];
    }];
  }];
}

/** @fn updateEmailPasswordWithCompletion:
    @brief Updates email and password for automatic manual tests, and signs user in with new email
        and password.
    @param completion The completion block to continue the automatic test flow.
 */
- (void)updateEmailPasswordWithCompletion:(void(^)(void))completion {
  FIRAuth *auth = [FIRAuth auth];
  [auth.currentUser updateEmail:kFakeEmail completion:^(NSError *_Nullable error) {
    if (error) {
      [self logFailure:@"update email failed" error:error];
      [self logFailedTest:@"Update email should succeed when properly signed-in."];
      return;
    }
    [self logSuccess:@"update email succeeded."];
    [auth.currentUser updatePassword:kFakePassword completion:^(NSError *_Nullable error) {
      if (error) {
        [self logFailure:@"update password failed" error:error];
        [self logFailedTest:@"Update password should succeed when properly signed-in."];
        return;
      }
      [self logSuccess:@"update password succeeded."];
      #warning TODO(zsika) Test should check for sign out errors.
      [auth signOut:NULL];
      FIRAuthCredential *credential =
        [FIREmailPasswordAuthProvider credentialWithEmail:kFakeEmail password:kFakePassword];
      [auth signInWithCredential:credential
                       completion:^(FIRUser *_Nullable user,
                                    NSError *_Nullable error) {
        if (error) {
          [self logFailure:@"sign-in with Email/Password failed" error:error];
          [self logFailedTest:@"sign-in with Email/Password should succeed."];
          return;
        }
        [self logSuccess:@"sign-in with Email/Password succeeded."];
        // Delete the user so that we can reuse the fake email address for subsequent tests.
        [auth.currentUser deleteWithCompletion:^(NSError *_Nullable error) {
          if (error) {
            [self logFailure:@"Failed to delete user." error:error];
            [self logFailedTest:@"Deleting a user that was recently signed-in should succeed"];
            return;
          }
        [self logSuccess:@"User deleted."];
        completion();
        }];
      }];
    }];
  }];
}

/** @fn updateDisplayNameAndPhotoURlWithCompletion:
    @brief Automatically executes the manual test for setting displayName and photoUrl.
    @param completion The completion block to continue the automatic test flow.
 */
- (void)updateDisplayNameAndPhotoURlWithCompletion:(void(^)(void))completion {
  FIRAuth *auth = [FIRAuth auth];
  FIRUserProfileChangeRequest *changeRequest = [auth.currentUser profileChangeRequest];
  changeRequest.photoURL = [NSURL URLWithString:kFakeDisplayPhotoUrl];
  [changeRequest commitChangesWithCompletion:^(NSError *_Nullable error) {
    if (error) {
      [self logFailure:@"set photo URL failed" error:error];
      [self logFailedTest:@"Change photo Url should succeed when signed-in."];
      return;
    }
    [self logSuccess:@"set PhotoURL succeeded."];
    FIRUserProfileChangeRequest *changeRequest = [auth.currentUser profileChangeRequest];
    changeRequest.displayName = kFakeDisplayName;
    [changeRequest commitChangesWithCompletion:^(NSError *_Nullable error) {
      if (error) {
        [self logFailure:@"set display name failed" error:error];
        [self logFailedTest:@"Change display name should succeed when signed-in."];
        return;
      }
      [self logSuccess:@"set display name succeeded."];
      completion();
    }];
  }];
}

/** @fn addListener
    @brief Adds an auth state did change listener (block).
 */
- (void)addListener {
  __weak typeof(self) weakSelf = self;
  NSUInteger index = _authStateDidChangeListeners.count;
  NSString *addedLogString =
      [NSString stringWithFormat:@"Auth State Did Change Listener with index #%lu was added.",
                                 (unsigned long)index];
  [self log:addedLogString];
  NSString *logString =
      [NSString stringWithFormat:@"Auth State Did Change Listener with index #%lu was invoked.",
                                 (unsigned long)index];
  FIRAuthStateDidChangeListenerHandle handle =
      [[FIRAuth auth] addAuthStateDidChangeListener:^(FIRAuth *_Nonnull auth,
                                                      FIRUser *_Nullable user) {
        [weakSelf log:logString];
      }];
  [_authStateDidChangeListeners addObject:handle];
}

/** @fn removeListener
    @brief Removes an auth state did change listener (block).
 */
- (void)removeListener {
  NSUInteger index = _authStateDidChangeListeners.count - 1;
  FIRAuthStateDidChangeListenerHandle handle = _authStateDidChangeListeners.lastObject;
  [[FIRAuth auth] removeAuthStateDidChangeListener:handle];
  [_authStateDidChangeListeners removeObject:handle];
  NSString *logString =
      [NSString stringWithFormat:@"Auth State Did Change Listener with index #%lu was removed.",
                                 (unsigned long)index];
  [self log:logString];
}

/** @fn log:
    @brief Prints a log message to the sample app console.
    @param string The string to add to the console.
 */
- (void)log:(NSString *)string {
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
  NSString *date = [dateFormatter stringFromDate:[NSDate date]];
  if (!_consoleString) {
    _consoleString = [NSMutableString string];
  }
  [_consoleString appendString:[NSString stringWithFormat:@"%@  %@\n", date, string]];
  _consoleTextView.text = _consoleString;

  CGRect targetRect = CGRectMake(0, _consoleTextView.contentSize.height - 1, 1, 1);
  [_consoleTextView scrollRectToVisible:targetRect animated:YES];
}

/** @fn logSuccess:
    @brief Wraps a string into a succeful log message format.
    @param string Part of the log message.
    @remarks The @string parameter should be a string ending with a period, as it is the end of the
        log message.
 */
- (void)logSuccess:(NSString *)string {
  [self log:[NSString stringWithFormat:@"SUCCESS: %@", string]];
}

/** @fn logFailure:
    @brief Wraps a string into a failed log message format.
    @param string Part of the message to wrap.
    @remarks The @string parameter should be a string that NEVER ends with a period, as it is
        guaranteed not to be the last part fo the log message.
 */
- (void)logFailure:(NSString *)string error:(NSError *) error {
  NSString *message =
      [NSString stringWithFormat:@"FAILURE: %@  Error Description: %@.", string, error.description];
  [self log:message];
}

/** @fn logTestFailed
    @brief Logs test failure to the console.
    @param reason The reason why the test is considered a failure.
    @remarks The calling method should immediately terminate after invoking this method i.e by
        return statement or end of fucntions. The @reason parameter should be a string ending with a
        period, as it is the end of the log message.
 */
- (void)logFailedTest:( NSString *_Nonnull )reason {
  [self log:[NSString stringWithFormat:@"FAILIURE: TEST FAILED - %@", reason]];
}

/** @fn presentSettings
    @brief Invoked when the settings row is pressed.
 */
- (void)presentSettings {
  SettingsViewController *settingsViewController = [[SettingsViewController alloc]
      initWithNibName:NSStringFromClass([SettingsViewController class])
               bundle:nil];
  [self presentViewController:settingsViewController animated:YES completion:nil];
}

/** @fn presentUserInfo
    @brief Invoked when the user info row is pressed.
 */
- (void)presentUserInfo {
  UserInfoViewController *userInfoViewController =
      [[UserInfoViewController alloc] initWithUser:[FIRAuth auth].currentUser];
  [self presentViewController:userInfoViewController animated:YES completion:nil];
}

/** @fn presentUserInMemoryInfo
    @brief Invoked when the user in memory info row is pressed.
 */
- (void)presentUserInMemoryInfo {
  UserInfoViewController *userInfoViewController =
      [[UserInfoViewController alloc] initWithUser:_userInMemory];
  [self presentViewController:userInfoViewController animated:YES completion:nil];
}

/** @fn signInGoogle
    @brief Invoked when "Sign in with Google" row is pressed.
 */
- (void)signInGoogle {
  [self signinWithProvider:[AuthProviders google] retrieveData:NO];
}

/** @fn signInGoogleAndRetrieveData
    @brief Invoked when "Sign in with Google and retrieve data" row is pressed.
 */
- (void)signInGoogleAndRetrieveData {
  [self signinWithProvider:[AuthProviders google] retrieveData:YES];
}

/** @fn signInFacebook
    @brief Invoked when "Sign in with Facebook" row is pressed.
 */
- (void)signInFacebook {
  [self signinWithProvider:[AuthProviders facebook] retrieveData:NO];
}

/** @fn signInFacebookAndRetrieveData
    @brief Invoked when "Sign in with Facebook and retrieve data" row is pressed.
 */
- (void)signInFacebookAndRetrieveData {
  [self signinWithProvider:[AuthProviders facebook] retrieveData:YES];
}

/** @fn signInEmailPassword
    @brief Invoked when "sign in with Email/Password" row is pressed.
 */
- (void)signInEmailPassword {
  [self showTextInputPromptWithMessage:@"Email Address:"
                       completionBlock:^(BOOL userPressedOK, NSString *_Nullable email) {
    if (!userPressedOK || !email.length) {
      return;
    }
    [self showTextInputPromptWithMessage:@"Password:"
                         completionBlock:^(BOOL userPressedOK, NSString *_Nullable password) {
      if (!userPressedOK) {
        return;
      }
      FIRAuthCredential *credential =
          [FIREmailPasswordAuthProvider credentialWithEmail:email
                                                   password:password];
      [self showSpinner:^{
        [[FIRAuth auth] signInWithCredential:credential
                                  completion:^(FIRUser *_Nullable user, NSError *_Nullable error) {
          [self hideSpinner:^{
            if (error) {
              [self logFailure:@"sign-in with Email/Password failed" error:error];
            } else {
              [self logSuccess:@"sign-in with Email/Password succeeded."];
            }
            [self showTypicalUIForUserUpdateResultsWithTitle:@"Sign-In Error" error:error];
          }];
        }];
      }];
    }];
  }];
}

/** @fn signUpNewEmail
    @brief Invoked if sign-in is attempted with new email/password.
    @remarks Should only be called if @c FIRAuthErrorCodeInvalidEmail is encountered on attepmt to
        sign in with email/password.
 */
- (void)signUpNewEmail:(NSString *)email
              password:(NSString *)password
              callback:(nullable FIRAuthResultCallback)callback {
  [[FIRAuth auth] createUserWithEmail:email
                             password:password
                           completion:^(FIRUser *_Nullable user, NSError *_Nullable error) {
    if (error) {
      [self logFailure:@"sign-up with Email/Password failed" error:error];
      if (callback) {
        callback(nil, error);
      }
    } else {
      [self logSuccess:@"sign-up with Email/Password succeeded."];
      if (callback) {
        callback(user, nil);
      }
    }
    [self showTypicalUIForUserUpdateResultsWithTitle:@"Sign-In" error:error];
  }];
}

/** @fn signInWithCustomToken
    @brief Signs the user in using a manually-entered custom token.
 */
- (void)signInWithCustomToken {
  CustomTokenDataEntryViewControllerCompletion action =
      ^(BOOL cancelled, NSString *_Nullable userEnteredTokenText) {
        if (cancelled) {
          [self log:@"CANCELLED:sign-in with custom token cancelled."];
          return;
        }

        [self doSignInWithCustomToken:userEnteredTokenText];
      };
  CustomTokenDataEntryViewController *dataEntryViewController =
      [[CustomTokenDataEntryViewController alloc] initWithCompletion:action];
  [self presentViewController:dataEntryViewController animated:YES completion:nil];
}

/** @fn signOut
    @brief Signs the user out.
 */
- (void)signOut {
  [[AuthProviders google] signOut];
  [[AuthProviders facebook] signOut];
  [[FIRAuth auth] signOut:NULL];
}

/** @fn deleteAccount
    @brief Deletes the current user account and signs the user out.
 */
- (void)deleteAccount {
  FIRUser *user = [self user];
  [user deleteWithCompletion:^(NSError *_Nullable error) {
    if (error) {
      [self logFailure:@"delete account failed" error:error];
    }
    [self showTypicalUIForUserUpdateResultsWithTitle:kDeleteUserText error:error];
  }];
}

/** @fn reauthenticateGoogle
    @brief Asks the user to reauthenticate with Google.
 */
- (void)reauthenticateGoogle {
  [self reauthenticate:[AuthProviders google] retrieveData:NO];
}

/** @fn reauthenticateGoogleAndRetrieveData
    @brief Asks the user to reauthenticate with Google and retrieve additional data.
 */
- (void)reauthenticateGoogleAndRetrieveData {
  [self reauthenticate:[AuthProviders google] retrieveData:YES];
}

/** @fn reauthenticateFB
    @brief Asks the user to reauthenticate with Facebook.
 */
- (void)reauthenticateFB {
  [self reauthenticate:[AuthProviders facebook] retrieveData:NO];
}

/** @fn reauthenticateFBAndRetrieveData
    @brief Asks the user to reauthenticate with Facebook and retrieve additional data.
 */
- (void)reauthenticateFBAndRetrieveData {
  [self reauthenticate:[AuthProviders facebook] retrieveData:YES];
}

/** @fn reauthenticateEmailPassword
    @brief Asks the user to reauthenticate with email/password.
 */
- (void)reauthenticateEmailPassword {
  [self showEmailPasswordDialogWithCompletion:^(FIRAuthCredential *credential) {
    [self showSpinner:^{
      [[self user] reauthenticateWithCredential:credential
                                     completion:^(NSError *_Nullable error) {
        if (error) {
          [self logFailure:@"reauthicate with email/password failed" error:error];
        } else {
          [self logSuccess:@"reauthicate with email/password succeeded."];
        }
        [self hideSpinner:^{
          [self showTypicalUIForUserUpdateResultsWithTitle:kReauthenticateEmailText error:error];
        }];
      }];
    }];
  }];
}

/** @fn reauthenticate:
    @brief Reauthenticates user.
    @param authProvider The auth provider to use for reauthentication.
    @param retrieveData Defines if additional provider data should be read.
 */
- (void)reauthenticate:(id<AuthProvider>)authProvider retrieveData:(BOOL)retrieveData {
  FIRUser *user = [self user];
  if (!user) {
    #warning TODO(zsika) Handle case.
    return;
  }
  [authProvider getAuthCredentialWithPresentingViewController:self
                                                     callback:^(FIRAuthCredential *credential,
                                                                NSError *error) {
    if (credential) {
      FIRAuthDataResultCallback completion = ^(FIRAuthDataResult *_Nullable authResult,
                                               NSError *_Nullable error) {
        if (error) {
          [self logFailure:@"reauthenticate operation failed" error:error];
        } else {
          [self logSuccess:@"reauthenticate operation succeeded."];
        }
        if (authResult.additionalUserInfo) {
          [self logSuccess:
              [NSString stringWithFormat:@"%@", authResult.additionalUserInfo.profile]];
        }
        [self showTypicalUIForUserUpdateResultsWithTitle:@"Reauthenticate" error:error];
      };
      FIRUserProfileChangeCallback callback = ^(NSError *_Nullable error) {
        completion(nil, error);
      };
      if (retrieveData) {
        [user reauthenticateAndRetrieveDataWithCredential:credential completion:completion];
      } else {
        [user reauthenticateWithCredential:credential completion:callback];
      }
    }
  }];
}

/** @fn signinWithProvider:
    @brief Signs in the user with provided auth provider.
    @param authProvider The auth provider to use for sign-in.
    @param retrieveData Defines if additional provider data should be read.
 */
- (void)signinWithProvider:(id<AuthProvider>)authProvider retrieveData:(BOOL)retrieveData {
  FIRAuth *auth = [FIRAuth auth];
  if (!auth) {
    #warning TODO(zsika) Handle case.
    return;
  }
  [authProvider getAuthCredentialWithPresentingViewController:self
                                                     callback:^(FIRAuthCredential *credential,
                                                                NSError *error) {
    if (credential) {
      FIRAuthDataResultCallback completion = ^(FIRAuthDataResult *_Nullable authResult,
                                               NSError *_Nullable error) {
        if (error) {
          [self logFailure:@"sign-in with provider failed" error:error];
        } else {
          [self logSuccess:@"sign-in with provider succeeded."];
        }
        if (authResult.additionalUserInfo) {
          [self logSuccess:
              [NSString stringWithFormat:@"%@", authResult.additionalUserInfo.profile]];
        }
        [self showTypicalUIForUserUpdateResultsWithTitle:@"Sign-In" error:error];
      };
      FIRAuthResultCallback callback = ^(FIRUser *_Nullable user,
                                         NSError *_Nullable error) {
        completion(nil, error);
      };
      if (retrieveData) {
        [auth signInAndRetrieveDataWithCredential:credential completion:completion];
      } else {
        [auth signInWithCredential:credential completion:callback];
      }
    }
  }];
}

/** @fn tokenCallback
    @return A callback block to show the token.
 */
- (FIRAuthTokenCallback)tokenCallback {
  return ^(NSString *_Nullable token, NSError *_Nullable error) {
    if (error) {
      [self showMessagePromptWithTitle:kTokenRefreshErrorAlertTitle
                               message:error.localizedDescription
                      showCancelButton:NO
                            completion:nil];
      [self logFailure:@"refresh token failed" error:error];
      return;
    }
    [self logSuccess:@"refresh token succeeded."];
    [self showMessagePromptWithTitle:kTokenRefreshedAlertTitle
                             message:token
                    showCancelButton:NO
                          completion:nil];
  };
}

/** @fn getUserTokenWithForce:
    @brief Gets the token from @c FIRUser , optionally a refreshed one.
    @param force Whether the refresh is forced or not.
 */
- (void)getUserTokenWithForce:(BOOL)force {
  [[self user] getTokenForcingRefresh:force completion:[self tokenCallback]];
}

/** @fn getAppTokenWithForce:
    @brief Gets the token from @c FIRApp , optionally a refreshed one.
    @param force Whether the refresh is forced or not.
 */
- (void)getAppTokenWithForce:(BOOL)force {
  [[FIRApp defaultApp] getTokenForcingRefresh:force withCallback:[self tokenCallback]];
}

/** @fn setDisplayName
    @brief Changes the display name of the current user.
 */
- (void)setDisplayName {
  [self showTextInputPromptWithMessage:@"Display Name:"
                       completionBlock:^(BOOL userPressedOK, NSString *_Nullable userInput) {
    if (!userPressedOK || !userInput.length) {
      return;
    }
    [self showSpinner:^{
      FIRUserProfileChangeRequest *changeRequest = [[self user] profileChangeRequest];
      changeRequest.displayName = userInput;
      [changeRequest commitChangesWithCompletion:^(NSError *_Nullable error) {
        [self hideSpinner:^{
          if (error) {
            [self logFailure:@"set display name failed" error:error];
          } else {
            [self logSuccess:@"set display name succeeded."];
          }
          [self showTypicalUIForUserUpdateResultsWithTitle:kSetDisplayNameTitle error:error];
        }];
      }];
    }];
  }];
}

/** @fn setPhotoURL
    @brief Changes the photo url of the current user.
 */
- (void)setPhotoURL {
  [self showTextInputPromptWithMessage:@"Photo URL:"
                       completionBlock:^(BOOL userPressedOK, NSString *_Nullable userInput) {
    if (!userPressedOK || !userInput.length) {
      return;
    }

    [self showSpinner:^{
      FIRUserProfileChangeRequest *changeRequest = [[self user] profileChangeRequest];
      changeRequest.photoURL = [NSURL URLWithString:userInput];
      [changeRequest commitChangesWithCompletion:^(NSError *_Nullable error) {
        if (error) {
          [self logFailure:@"set photo URL failed" error:error];
        } else {
          [self logSuccess:@"set Photo URL succeeded."];
        }
        [self hideSpinner:^{
          [self showTypicalUIForUserUpdateResultsWithTitle:kSetPhotoURLText error:error];
        }];
      }];
    }];
  }];
}

/** @fn reloadUser
    @brief Reloads the user from server.
 */
- (void)reloadUser {
  [self showSpinner:^() {
    [[self user] reloadWithCompletion:^(NSError *_Nullable error) {
      if (error) {
        [self logFailure:@"reload user failed" error:error];
      } else {
        [self logSuccess:@"reload user succeeded."];
      }
      [self hideSpinner:^() {
        [self showTypicalUIForUserUpdateResultsWithTitle:kReloadText error:error];
      }];
    }];
  }];
}

/** @fn linkWithAuthProvider:retrieveData:
    @brief Asks the user to sign in with an auth provider and link the current user with it.
    @param authProvider The auth provider to sign in and link with.
    @param retrieveData Defines if additional provider data should be read.
 */
- (void)linkWithAuthProvider:(id<AuthProvider>)authProvider retrieveData:(BOOL)retrieveData {
  FIRUser *user = [self user];
  if (!user) {
    return;
  }
  [authProvider getAuthCredentialWithPresentingViewController:self
                                                     callback:^(FIRAuthCredential *credential,
                                                                NSError *error) {
    if (credential) {
      FIRAuthDataResultCallback completion = ^(FIRAuthDataResult *_Nullable authResult,
                                               NSError *_Nullable error) {
        if (error) {
          [self logFailure:@"link auth provider failed" error:error];
        } else {
          [self logSuccess:@"link auth provider succeeded."];
        }
        if (authResult.additionalUserInfo) {
          [self logSuccess:
              [NSString stringWithFormat:@"%@", authResult.additionalUserInfo.profile]];
        }
        if (retrieveData) {
          [self showUIForAuthDataResultWithResult:authResult error:error];
        } else {
          [self showTypicalUIForUserUpdateResultsWithTitle:@"Link Account" error:error];
        }
      };
      FIRAuthResultCallback callback = ^(FIRUser *_Nullable user,
                                         NSError *_Nullable error) {
        completion(nil, error);
      };
      if (retrieveData) {
        [user linkAndRetrieveDataWithCredential:credential completion:completion];
      } else {
        [user linkWithCredential:credential completion:callback];
      }
    }
  }];
}

/** @fn linkWithGoogle
    @brief Asks the user to sign in with Google and link the current user with this Google account.
 */
- (void)linkWithGoogle {
  [self linkWithAuthProvider:[AuthProviders google] retrieveData:NO];
}

/** @fn linkWithGoogleAndRetrieveData
    @brief Asks the user to sign in with Google and link the current user with this Google account
        and retrieve additional data.
 */
- (void)linkWithGoogleAndRetrieveData {
  [self linkWithAuthProvider:[AuthProviders google] retrieveData:YES];
}

/** @fn linkWithFacebook
    @brief Asks the user to sign in with Facebook and link the current user with this Facebook
        account.
 */
- (void)linkWithFacebook {
  [self linkWithAuthProvider:[AuthProviders facebook] retrieveData:NO];
}

/** @fn linkWithFacebookAndRetrieveData
    @brief Asks the user to sign in with Facebook and link the current user with this Facebook
        account and retrieve additional data.
 */
- (void)linkWithFacebookAndRetrieveData {
  [self linkWithAuthProvider:[AuthProviders facebook] retrieveData:YES];
}

/** @fn linkWithEmailPassword
    @brief Asks the user to sign in with Facebook and link the current user with this Facebook
        account.
 */
- (void)linkWithEmailPassword {
  [self showEmailPasswordDialogWithCompletion:^(FIRAuthCredential *credential) {
    [self showSpinner:^{
      [[self user] linkWithCredential:credential
                           completion:^(FIRUser *user, NSError *_Nullable error) {
        if (error) {
          [self logFailure:@"link Email/Password failed" error:error];
        } else {
          [self logSuccess:@"link Email/Password succeeded."];
        }
        [self hideSpinner:^{
          [self showTypicalUIForUserUpdateResultsWithTitle:kLinkWithEmailPasswordText error:error];
        }];
      }];
    }];
  }];
}

/** @fn showEmailPasswordDialogWithCompletion:
    @brief shows email/password input dialog.
    @param completion The completion block that will do some operation on the credential email
        /passwowrd credential obtained.
 */
- (void)showEmailPasswordDialogWithCompletion:(ShowEmailPasswordDialogCompletion)completion {
  [self showTextInputPromptWithMessage:@"Email Address:"
                       completionBlock:^(BOOL userPressedOK, NSString *_Nullable email) {
    if (!userPressedOK || !email.length) {
      return;
    }
    [self showTextInputPromptWithMessage:@"Password:"
                         completionBlock:^(BOOL userPressedOK, NSString *_Nullable password) {
      if (!userPressedOK || !password.length) {
        return;
      }
      FIRAuthCredential *credential = [FIREmailPasswordAuthProvider credentialWithEmail:email
                                                                               password:password];
      completion(credential);
    }];
  }];
}

/** @fn unlinkFromProvider:
    @brief Unlinks the current user from the provider with the specified provider ID.
    @param provider The provider ID of the provider to unlink the current user's account from.
 */
- (void)unlinkFromProvider:(NSString *)provider {
  [[self user] unlinkFromProvider:provider
                       completion:^(FIRUser *_Nullable user,
                                    NSError *_Nullable error) {
    if (error) {
      [self logFailure:@"unlink auth provider failed" error:error];
    } else {
      [self logSuccess:@"unlink auth provider succeeded."];
    }
    [self showTypicalUIForUserUpdateResultsWithTitle:kUnlinkTitle error:error];
  }];
}

/** @fn getProvidersForEmail
    @brief Prompts the user for an email address, calls @c FIRAuth.getProvidersForEmail:callback:
        and displays the result.
 */
- (void)getProvidersForEmail {
  [self showTextInputPromptWithMessage:@"Email:"
                       completionBlock:^(BOOL userPressedOK, NSString *_Nullable userInput) {
    if (!userPressedOK || !userInput.length) {
      return;
    }

    [self showSpinner:^{
      [[FIRAuth auth] fetchProvidersForEmail:userInput
                                  completion:^(NSArray<NSString *> *_Nullable providers,
                                               NSError *_Nullable error) {
        if (error) {
          [self logFailure:@"get providers for email failed" error:error];
        } else {
          [self logSuccess:@"get providers for email succeeded."];
        }
        [self hideSpinner:^{
          if (error) {
            [self showMessagePrompt:error.localizedDescription];
            return;
          }

          [self showMessagePrompt:[providers componentsJoinedByString:@", "]];
        }];
      }];
    }];
  }];
}

/** @fn requestVerifyEmail
    @brief Requests a "verify email" email be sent.
 */
- (void)requestVerifyEmail {
  [self showSpinner:^{
    [[self user] sendEmailVerificationWithCompletion:^(NSError *_Nullable error) {
      [self hideSpinner:^{
        if (error) {
          [self logFailure:@"request verify email failed" error:error];
          [self showMessagePrompt:error.localizedDescription];
          return;
        }
        [self logSuccess:@"request verify email succeeded."];
        [self showMessagePrompt:@"Sent"];
      }];
    }];
  }];
}

/** @fn requestPasswordReset
    @brief Requests a "password reset" email be sent.
 */
- (void)requestPasswordReset {
  [self showTextInputPromptWithMessage:@"Email:"
                       completionBlock:^(BOOL userPressedOK, NSString *_Nullable userInput) {
    if (!userPressedOK || !userInput.length) {
      return;
    }
    [self showSpinner:^{
      [[FIRAuth auth] sendPasswordResetWithEmail:userInput completion:^(NSError *_Nullable error) {
        [self hideSpinner:^{
          if (error) {
            [self logFailure:@"request password reset failed" error:error];
            [self showMessagePrompt:error.localizedDescription];
            return;
          }
          [self logSuccess:@"request password reset succeeded."];
          [self showMessagePrompt:@"Sent"];
        }];
      }];
    }];
  }];
}

/** @fn resetPassword
    @brief Performs a password reset operation.
 */
- (void)resetPassword {
  [self showTextInputPromptWithMessage:@"OOB Code:"
                       completionBlock:^(BOOL userPressedOK, NSString *_Nullable userInput) {
    if (!userPressedOK || !userInput.length) {
      return;
    }
    NSString *code =  userInput;

    [self showTextInputPromptWithMessage:@"New Password:"
                         completionBlock:^(BOOL userPressedOK, NSString *_Nullable userInput) {
      if (!userPressedOK || !userInput.length) {
        return;
      }

      [self showSpinner:^{
        [[FIRAuth auth] confirmPasswordResetWithCode:code
                                         newPassword:userInput
                                          completion:^(NSError *_Nullable error) {
          [self hideSpinner:^{
            if (error) {
              [self logFailure:@"Password reset failed" error:error];
              [self showMessagePrompt:error.localizedDescription];
              return;
            }
            [self logSuccess:@"Password reset succeeded."];
            [self showMessagePrompt:@"Password reset succeeded."];
          }];
        }];
      }];
    }];
  }];
}

/** @fn checkActionCode
    @brief Performs a "check action code" operation.
 */
- (void)checkActionCode {
  [self showTextInputPromptWithMessage:@"OOB Code:"
                       completionBlock:^(BOOL userPressedOK, NSString *_Nullable userInput) {
    if (!userPressedOK || !userInput.length) {
      return;
    }
    [self showSpinner:^{
      [[FIRAuth auth] checkActionCode:userInput completion:^(FIRActionCodeInfo *_Nullable info,
                                                             NSError *_Nullable error) {
        [self hideSpinner:^{
          if (error) {
            [self logFailure:@"Check action code failed" error:error];
            [self showMessagePrompt:error.localizedDescription];
            return;
          }
          [self logSuccess:@"Check action code succeeded."];
          NSString *email = [info dataForKey:FIRActionCodeEmailKey];
          NSString *operation = [self nameForActionCodeOperation:info.operation];
          NSString *infoMessage =
            [[NSString alloc] initWithFormat:@"Email: %@\n Operation: %@", email, operation];
          [self showMessagePrompt:infoMessage];
        }];
      }];
    }];
  }];
}

/** @fn applyActionCode
    @brief Performs a "apply action code" operation.
 */
- (void)applyActionCode {
  [self showTextInputPromptWithMessage:@"OOB Code:"
                       completionBlock:^(BOOL userPressedOK, NSString *_Nullable userInput) {
    if (!userPressedOK || !userInput.length) {
      return;
    }
    [self showSpinner:^{

      [[FIRAuth auth] applyActionCode:userInput completion:^(NSError *_Nullable error) {
        [self hideSpinner:^{
          if (error) {
            [self logFailure:@"Apply action code failed" error:error];
            [self showMessagePrompt:error.localizedDescription];
            return;
          }
          [self logSuccess:@"Apply action code succeeded."];
          [self showMessagePrompt:@"Action code was properly applied."];
        }];
      }];
    }];
  }];
}

/** @fn verifyPasswordResetCode
    @brief Performs a "verify password reset code" operation.
 */
- (void)verifyPasswordResetCode {
  [self showTextInputPromptWithMessage:@"OOB Code:"
                       completionBlock:^(BOOL userPressedOK, NSString *_Nullable userInput) {
    if (!userPressedOK || !userInput.length) {
      return;
    }
    [self showSpinner:^{
      [[FIRAuth auth] verifyPasswordResetCode:userInput completion:^(NSString *_Nullable email,
                                                                     NSError *_Nullable error) {
        [self hideSpinner:^{
          if (error) {
            [self logFailure:@"Verify password reset code failed" error:error];
            [self showMessagePrompt:error.localizedDescription];
            return;
          }
          [self logSuccess:@"Verify password resest code succeeded."];
          NSString *alertMessage =
            [[NSString alloc] initWithFormat:@"Code verified for email: %@", email];
          [self showMessagePrompt:alertMessage];
        }];
      }];
    }];
  }];
}


/** @fn nameForActionCodeOperation
    @brief Returns the string value of the provided FIRActionCodeOperation value.
    @param operation the FIRActionCodeOperation value to convert to string.
    @return String conversion of FIRActionCodeOperation value.
 */
- (NSString *)nameForActionCodeOperation:(FIRActionCodeOperation)operation {
  switch (operation) {
  case FIRActionCodeOperationVerifyEmail:
    return @"Verify Email";
  case FIRActionCodeOperationPasswordReset:
    return @"Password Reset";
  case FIRActionCodeOperationUnknown:
    return @"Unknown action";
  }
}

/** @fn updateEmail
    @brief Changes the email address of the current user.
 */
- (void)updateEmail {
  [self showTextInputPromptWithMessage:@"Email Address:"
                       completionBlock:^(BOOL userPressedOK, NSString *_Nullable userInput) {
    if (!userPressedOK || !userInput.length) {
      return;
    }

    [self showSpinner:^{
      [[self user] updateEmail:userInput completion:^(NSError *_Nullable error) {
        if (error) {
          [self logFailure:@"update email failed" error:error];
        } else {
          [self logSuccess:@"update email succeeded."];
        }
        [self hideSpinner:^{
          [self showTypicalUIForUserUpdateResultsWithTitle:kUpdateEmailText error:error];
        }];
      }];
    }];
  }];
}

/** @fn updatePassword
    @brief Updates the password of the current user.
 */
- (void)updatePassword {
  [self showTextInputPromptWithMessage:@"New Password:"
                       completionBlock:^(BOOL userPressedOK, NSString *_Nullable userInput) {
    if (!userPressedOK) {
      return;
    }

    [self showSpinner:^{
      [[self user] updatePassword:userInput completion:^(NSError *_Nullable error) {
        if (error) {
          [self logFailure:@"update password failed" error:error];
        } else {
          [self logSuccess:@"update password succeeded."];
        }
        [self hideSpinner:^{
          [self showTypicalUIForUserUpdateResultsWithTitle:kUpdatePasswordText error:error];
        }];
      }];
    }];
  }];
}

/** @fn createUser
    @brief Creates a new user.
 */
- (void)createUser {
  [self showTextInputPromptWithMessage:@"Email:"
                       completionBlock:^(BOOL userPressedOK, NSString *_Nullable email) {
    if (!userPressedOK || !email.length) {
      return;
    }

    [self showTextInputPromptWithMessage:@"Password:"
                         completionBlock:^(BOOL userPressedOK, NSString *_Nullable password) {
      if (!userPressedOK) {
        return;
      }

      [self showSpinner:^{
        [[FIRAuth auth] createUserWithEmail:email
                                   password:password
                                 completion:^(FIRUser *_Nullable user, NSError *_Nullable error) {
          if (error) {
            [self logFailure:@"create user failed" error:error];
          } else {
            [self logSuccess:@"create user succeeded."];
          }
          [self hideSpinner:^{
            [self showTypicalUIForUserUpdateResultsWithTitle:kCreateUserTitle error:error];
          }];
        }];
      }];
    }];
  }];
}

/** @fn signInWithPhoneNumber
    @brief Allows sign in with phone number.
 */
- (void)signInWithPhoneNumber {
  [self showTextInputPromptWithMessage:@"Phone #:"
                       completionBlock:^(BOOL userPressedOK, NSString *_Nullable phoneNumber) {
    if (!userPressedOK || !phoneNumber.length) {
      return;
    }
    [self showSpinner:^{
      [[FIRPhoneAuthProvider provider] verifyPhoneNumber:phoneNumber
                                              completion:^(NSString *_Nullable verificationID,
                                                           NSError *_Nullable error) {
        if (error) {
          [self logFailure:@"failed to send verification code" error:error];
          return;
        }
        [self logSuccess:@"Code sent"];

        [self showTextInputPromptWithMessage:@"Verification code:"
                             completionBlock:^(BOOL userPressedOK,
                                               NSString *_Nullable verificationCode) {
          if (!userPressedOK || !verificationCode.length) {
            return;
          }
          [self showSpinner:^{
            FIRAuthCredential *credential =
                [[FIRPhoneAuthProvider provider] credentialWithVerificationID:verificationID
                                                             verificationCode:verificationCode];
            [[FIRAuth auth] signInWithCredential:credential
                                      completion:^(FIRUser *_Nullable user,
                                                  NSError *_Nullable error) {
              if (error) {
                [self logFailure:@"failed to verify phone number" error:error];
                return;
              }
            }];
          }];
        }];
        [self hideSpinner:^{
          [self showTypicalUIForUserUpdateResultsWithTitle:kCreateUserTitle error:error];
        }];
      }];
    }];
  }];
}

/** @fn updatePhoneNumber
    @brief Allows adding a verified phone number to the currently signed user.
 */
- (void)updatePhoneNumber {
  [self showTextInputPromptWithMessage:@"Phone #:"
                       completionBlock:^(BOOL userPressedOK, NSString *_Nullable phoneNumber) {
    if (!userPressedOK || !phoneNumber.length) {
      return;
    }
    [self showSpinner:^{
      [[FIRPhoneAuthProvider provider] verifyPhoneNumber:phoneNumber
                                              completion:^(NSString *_Nullable verificationID,
                                                           NSError *_Nullable error) {
        if (error) {
          [self logFailure:@"failed to send verification code" error:error];
          return;
        }
        [self logSuccess:@"Code sent"];

        [self showTextInputPromptWithMessage:@"Verification code:"
                             completionBlock:^(BOOL userPressedOK,
                                               NSString *_Nullable verificationCode) {
          if (!userPressedOK || !verificationCode.length) {
            return;
          }
          [self showSpinner:^{
            FIRPhoneAuthCredential *credential =
                [[FIRPhoneAuthProvider provider] credentialWithVerificationID:verificationID
                                                             verificationCode:verificationCode];
            [[self user] updatePhoneNumberCredential:credential
                                          completion:^(NSError *_Nullable error) {
              if (error) {
                [self logFailure:@"update phone number failed" error:error];
              } else {
                [self logSuccess:@"update phone number succeeded."];
              }
            }];
          }];
        }];
        [self hideSpinner:^{
          [self showTypicalUIForUserUpdateResultsWithTitle:kCreateUserTitle error:error];
        }];
      }];
    }];
  }];
}

/** @fn linkPhoneNumber
    @brief Allows linking a verified phone number to the currently signed user.
 */
- (void)linkPhoneNumber {
  [self showTextInputPromptWithMessage:@"Phone #:"
                       completionBlock:^(BOOL userPressedOK, NSString *_Nullable phoneNumber) {
    if (!userPressedOK || !phoneNumber.length) {
      return;
    }
    [self showSpinner:^{
      [[FIRPhoneAuthProvider provider] verifyPhoneNumber:phoneNumber
                                              completion:^(NSString *_Nullable verificationID,
                                                           NSError *_Nullable error) {
        if (error) {
          [self logFailure:@"failed to send verification code" error:error];
          return;
        }
        [self logSuccess:@"Code sent"];

        [self showTextInputPromptWithMessage:@"Verification code:"
                             completionBlock:^(BOOL userPressedOK,
                                               NSString *_Nullable verificationCode) {
          if (!userPressedOK || !verificationCode.length) {
            return;
          }
          [self showSpinner:^{
            FIRPhoneAuthCredential *credential =
                [[FIRPhoneAuthProvider provider] credentialWithVerificationID:verificationID
                                                             verificationCode:verificationCode];
            [[self user] linkWithCredential:credential
                                 completion:^(FIRUser *_Nullable user,
                                              NSError *_Nullable error) {
              if (error) {
                if (error.code == FIRAuthErrorCodeCredentialAlreadyInUse) {
                  [self showMessagePromptWithTitle:@"Phone number is already linked to another user"
                                           message:@"Tap Ok to sign in with that user now."
                                  showCancelButton:YES
                                        completion:^(BOOL userPressedOK,
                                                     NSString *_Nullable userInput) {
                    if (userPressedOK) {
                      // If FIRAuthErrorCodeCredentialAlreadyInUse error, sign in with the provided
                      // credential.
                      FIRPhoneAuthCredential *credential =
                          error.userInfo[FIRAuthUpdatedCredentialKey];
                      [[FIRAuth auth] signInWithCredential:credential
                                                completion:^(FIRUser *_Nullable user,
                                                             NSError *_Nullable error) {
                        if (error) {
                          [self logFailure:@"failed to verify phone number" error:error];
                          return;
                        }
                      }];
                    }
                  }];
                } else {
                  [self logFailure:@"link phone number failed" error:error];
                }
                return;
              }
              [self logSuccess:@"link phone number succeeded."];
            }];
          }];
        }];
        [self hideSpinner:^{
          [self showTypicalUIForUserUpdateResultsWithTitle:kCreateUserTitle error:error];
        }];
      }];
    }];
  }];
}

/** @fn signInAnonymously
    @brief Signs in as an anonymous user.
 */
- (void)signInAnonymously {
  [[FIRAuth auth] signInAnonymouslyWithCompletion:^(FIRUser *_Nullable user,
                                                    NSError *_Nullable error) {
    if (error) {
      [self logFailure:@"sign-in anonymously failed" error:error];
    } else {
      [self logSuccess:@"sign-in anonymously succeeded."];
    }
    [self showTypicalUIForUserUpdateResultsWithTitle:kSignInAnonymouslyButtonText error:error];
  }];
}

/** @fn signInWithGitHub
    @brief Signs in as a GitHub user. Prompts the user for an access token and uses this access
        token to create a GitHub (generic) credential for signing in.
 */
- (void)signInWithGitHub {
  // TODO:(zsika) Change this in favor of an AppAuth flow.
  [self showTextInputPromptWithMessage:@"GitHub Access Token:"
                       completionBlock:^(BOOL userPressedOK, NSString *_Nullable accessToekn) {
    if (!userPressedOK || !accessToekn.length) {
      return;
    }
    FIRAuthCredential *credential =
        [FIROAuthProvider credentialWithProviderID:FIRGitHubAuthProviderID accessToken:accessToekn];
    if (credential) {
        [[FIRAuth auth] signInWithCredential:credential completion:^(FIRUser *_Nullable user,
                                                                     NSError *_Nullable error) {
          if (error) {
            [self logFailure:@"sign-in with provider failed" error:error];
          } else {
            [self logSuccess:@"sign-in with provider succeeded."];
          }
          [self showTypicalUIForUserUpdateResultsWithTitle:@"Sign-In" error:error];
      }];
    }
  }];
}

/** @fn deleteApp
    @brief Deletes the @c FIRApp associated with our @c FIRAuth instance.
 */
- (void)deleteApp {
  [[FIRApp defaultApp] deleteApp:^(BOOL success) {
    [self log:success ? @"App deleted successfully." : @"Failed to delete app."];
  }];
}

#pragma mark - Helpers

/** @fn user
    @brief The user to use for user operations. Takes into account the "use signed-in user vs. use
        user in memory" setting.
 */
- (FIRUser *)user {
  return _useUserInMemory ? _userInMemory : [FIRAuth auth].currentUser;
}

/** @fn showTypicalUIForUserUpdateResultsWithTitle:error:
    @brief Shows a prompt if error is non-nil with the localized description of the error.
    @param resultsTitle The title of the prompt
    @param error The error details to display if non-nil.
 */
- (void)showTypicalUIForUserUpdateResultsWithTitle:(NSString *)resultsTitle
                                             error:(NSError *)error {
  if (error) {
    NSString *message = [NSString stringWithFormat:@"%@ (%ld)\n%@",
                                                   error.domain,
                                                   (long)error.code,
                                                   error.localizedDescription];
    [self showMessagePromptWithTitle:resultsTitle
                             message:message
                    showCancelButton:NO
                          completion:nil];
    return;
  }
  [self updateUserInfo];
}

/** @fn showUIForAuthDataResultWithResult:error:
    @brief Shows a prompt if error is non-nil with the localized description of the error.
    @param result The auth data result if non-nil.
    @param error The error details to display if non-nil.
 */
- (void)showUIForAuthDataResultWithResult:(FIRAuthDataResult *)result
                                    error:(NSError *)error {
  NSString *errorMessage = [NSString stringWithFormat:@"%@ (%ld)\n%@",
                                                      error.domain ?: @"",
                                                      (long)error.code,
                                                      error.localizedDescription ?: @""];
  [self showMessagePromptWithTitle:@"Error"
                           message:errorMessage
                  showCancelButton:NO
                        completion:^(BOOL userPressedOK,
                                     NSString *_Nullable userInput) {
    NSString *profileMessaage =
        [NSString stringWithFormat:@"%@", result.additionalUserInfo.profile ?: @""];
    [self showMessagePromptWithTitle:@"Profile Info"
                             message:profileMessaage
                    showCancelButton:NO
                          completion:nil];
    [self updateUserInfo];
  }];
}

- (void)doSignInWithCustomToken:(NSString *_Nullable)userEnteredTokenText {
  [[FIRAuth auth] signInWithCustomToken:userEnteredTokenText
                             completion:^(FIRUser *_Nullable user, NSError *_Nullable error) {
    if (error) {
      [self logFailure:@"sign-in with custom token failed" error:error];
      [self showMessagePromptWithTitle:kSignInErrorAlertTitle
                               message:error.localizedDescription
                      showCancelButton:NO
                            completion:nil];
      return;
    }
    [self logSuccess:@"sign-in with custom token succeeded."];
    [self showMessagePromptWithTitle:kSignedInAlertTitle
                             message:user.displayName
                    showCancelButton:NO
                          completion:nil];
  }];
}

- (void)updateUserInfo {
  [_userInfoTableViewCell updateContentsWithUser:[FIRAuth auth].currentUser];
  [_userInMemoryInfoTableViewCell updateContentsWithUser:_userInMemory];
}

- (void)authStateChangedForAuth:(NSNotification *)notification {
  [self updateUserInfo];
  if (notification) {
    [self log:@"received FIRAuthStateDidchange Notification."];
  }
}

/** @fn clearConsole
    @brief Clears the console text.
 */
- (IBAction)clearConsole:(id)sender {
  [_consoleString appendString:@"\n\n"];
  _consoleTextView.text = @"";
}

/** @fn copyConsole
    @brief Copies the current console string to the clipboard.
 */
- (IBAction)copyConsole:(id)sender {
  UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
  pasteboard.string = _consoleString ?: @"";
}

@end
