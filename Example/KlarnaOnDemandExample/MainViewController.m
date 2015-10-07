#import "AFNetworking/AFNetworking.h"
#import "MainViewController.h"
#import "KODRegistrationViewController.h"
#import "KODPreferencesViewController.h"
#import "KODContext.h"
#import "KODOriginProof.h"

#define ALERT(str) [[[UIAlertView alloc] initWithTitle:@"Alert" message:str delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show]

NSString *const UserTokenKey = @"user_token";
NSString *const BackendURL = @"https://secret-escarpment-2186.herokuapp.com/pay";

@implementation MainViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self initializeUIElements];
  [self updateUIElements];
}

#pragma mark Button clicks

- (IBAction)onBuyPressed:(id)sender {
  // if a token has not been previously created
  if([self hasUserToken]) {
    [self buyTicket];
  }
  else {
    [self openKlarnaRegistration];
  }
}

#pragma mark Order using Klarna

- (void) openKlarnaRegistration {
  // Create a new Klarna registration view-controller, initialized with MainViewController as event-handler.
  KODRegistrationViewController *registrationViewController = [[KODRegistrationViewController alloc] initWithDelegate:self];
  
  // Create navigation controller with Klarna registration view-controller as the root view controller.
  UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:registrationViewController];
  
  // Show navigation controller (in a modal presentation).
  [self presentViewController:navigationController
                     animated:YES
                   completion:nil];
}

- (IBAction) openKlarnaPreferences:(id)sender {
  // Create a new Klarna preferences view-controller, initialized with MainViewController as the event-handler, and the user token that was saved when the user completed the registration process.
  KODPreferencesViewController *preferencesViewController = [[KODPreferencesViewController alloc] initWithDelegate:self andToken:[self getUserToken]];
  
  // Create navigation controller with Klarna preferences view-controller as the root view controller.
  UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:preferencesViewController];
  
  // Show navigation controller (in a modal presentation).
  [self presentViewController:navigationController
                     animated:YES
                   completion:nil];
}

- (void) buyTicket {
  // create origin proof for order.
  KODOriginProof *originProof = [[KODOriginProof alloc] initWithAmount:9900
                                                              currency:@"SEK"
                                                             userToken:[self getUserToken]];
  
  // send order request to app-server.
  [self performPurchaseOfItemWithReference:@"TCKT0001" originProof:originProof];
}

- (void)performPurchaseOfItemWithReference:(NSString *)reference originProof:(KODOriginProof *)originProof {
  AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
  manager.requestSerializer = [AFJSONRequestSerializer serializer];
  NSString *userToken = [self getUserToken];

  NSDictionary *params = @{
                           @"origin_proof" : [originProof description],
                           @"reference" :    reference,
                           @"user_token" :   userToken
                           };

  [manager POST:BackendURL parameters:params
        success:^(AFHTTPRequestOperation *operation, id responseObject) {
          // show QR Code for the movie.
          [self showQRView];
        }
        failure:^(AFHTTPRequestOperation *operation, NSError *error) {
          // Display an error.
          NSString *errorMessage = [NSString stringWithFormat:@"%@%@", @"Failed to purchase ticket - ", error.localizedDescription];
          ALERT(errorMessage);
        }
   ];
}

#pragma mark Klarna registration delegate

- (void)klarnaRegistrationFailed:(KODRegistrationViewController *)controller {
  // You may also want to convey this failure to your user.
  // Dismiss Klarna registration view-controller.
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)klarnaRegistrationCancelled:(KODRegistrationViewController *)controller {
  // Dismiss Klarna registration view-controller.
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)klarnaRegistrationController:(KODRegistrationViewController *)controller finishedWithResult:(KODRegistrationResult *)registrationResult {
  // Dismiss Klarna registration view-controller.
  [self dismissViewControllerAnimated:YES completion:nil];

  // Saves the user token so that we can identify the user in future calls.
  [self saveUserToken:registrationResult.token];

  [self updateUIElements];
  
  [self buyTicket];
}

#pragma mark Klarna preferences delegate

- (void)klarnaPreferencesFailed:(KODPreferencesViewController *)controller {
  // Dismiss Klarna preferences view-controller.
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)klarnaPreferencesClosed:(KODPreferencesViewController *)controller {
  // Dismiss Klarna preferences view-controller.
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark User token persistence

/**
 *  Save user token locally in device.
 *  You may want to save this token on your backend server.
 *
 *  @param token Token that uniquely identifies the user.
 */
- (void)saveUserToken:(NSString *)token {
  NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
  [standardUserDefaults setValue:token forKey:UserTokenKey];
  [standardUserDefaults synchronize];
}

/**
 *  Get the token that was saved after registration finished.
 *
 *  @return A token that uniquely identifies the user, or nil of no token has been stored.
 */
- (NSString *)getUserToken {
  return [[NSUserDefaults standardUserDefaults] objectForKey:UserTokenKey];
}

- (bool)hasUserToken {
  return [self getUserToken] != nil;
}

# pragma mark UI behaviours

- (void)initializeUIElements {
  _buyButton.titleLabel.numberOfLines = 1;
  _buyButton.titleLabel.adjustsFontSizeToFitWidth = YES;
  _buyButton.titleLabel.lineBreakMode = NSLineBreakByClipping;
}

- (void)updateUIElements {
  _registerLabel.hidden = [self hasUserToken];
  _changePaymentButton.hidden = ![self hasUserToken];
  
  [self hideQRView:nil];
}

- (IBAction)hideQRView:(id)sender {
  self.QRView.hidden = YES;
}

- (void)showQRView {
  self.QRView.hidden = NO;
}

@end
