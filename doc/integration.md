#Integration Guide
This guide includes all information necessary to receive payments from a user of your application through Klarna. In this guide, you will see how to allow the user to register his device with Klarna, change payment preferences and perform purchases.

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
###Table of Contents

- [Including the SDK in your project](#including-the-sdk-in-your-project)
- [Supplying your API key](#supplying-your-api-key)
- [The registration view](#the-registration-view)
  - [Showing the view](#showing-the-view)
  - [Interacting with the view](#interacting-with-the-view)
    - [The KODRegistrationViewControllerDelegate protocol](#the-kodregistrationviewcontrollerdelegate-protocol)
  - [When should you show the registration view?](#when-should-you-show-the-registration-view)
- [Performing purchases](#performing-purchases)
  - [Purchase example](#purchase-example)
  - [Signing requests](#signing-requests)
- [The preferences view](#the-preferences-view)
  - [Showing the view](#showing-the-view-1)
  - [Interacting with the view](#interacting-with-the-view-1)
    - [The KODPreferencesViewControllerDelegate protocol](#the-kodpreferencesviewcontrollerdelegate-protocol)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

##Including the SDK in your project
This guide assumes you use [CocoaPods](http://cocoapods.org) to manage your project dependencies. If you do not, refer to our [official documentation (coming soon)](http://developers.klarna.com) for an alternative setup approach.

Simply open up your Podfile and add the following line:

    pod "Klarna-on-Demand"

##Supplying your API key
In order to use the SDK, you will need an API key to identify yourself. You can get one from our [developer site (coming soon)](http://developers.klarna.com/).

We recommend setting your API key in your AppDelegate in the manner shown below. If you don't have a key of your own yet the one listed below will work as well, but will not properly represent your application:

```objective-c
#import "AppDelegate.h"
#import "KODContext.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  // Set Klarna's API key. This is an actual test key that you can use to try things out,
  // though it would be best to use your personalized test key.
  [KODContext setApiKey:@"test_d8324b98-97ce-4974-88de-eaab2fdf4f14"];
  return YES;
}
@end
```

**Note:** API keys beginning with "test" always belong to the playground environment, so you may perform any action while using them without worry of subjecting users to any actual cost.

<a name="registration_view"></a>
##The registration view
Users must go through a quick one time registration process in order to pay using Klarna. To make this process as simple as possible, the SDK provides a registration view that you should present to your users. Once the registration process is complete, you will receive a token that will allow you to charge the user for purchases.

**Note:** It is important to point out that the registration view will not function properly without network access, and that it does not currently support a landscape orientation.

###Showing the view
For the sake of this example, assume we have a button that launches the registration view (we will cover a better approach [later](#when_to_show_registration)).

First off, import the registration view's header file into your view controller:

```objective-c
#import "KODRegistrationViewController.h"
```

Secondly, change the view controller which hosts the registration view to conform to the KODRegistrationViewControllerDelegate protocol, which we will talk about [shortly](#kod_registration_view_controller_delegate):

```objective-c
@interface MainViewController : UIViewController<KODRegistrationViewControllerDelegate>
// Various interface definitions
@end
```

Then, assuming the button's touch handler is called `onRegisterPressed`, set it up like this:

```objective-c
- (IBAction)onRegisterPressed:(id)sender {
  // Create a new Klarna registration view controller, initialized with the containing controller as its event-handler
  KODRegistrationViewController *registrationViewController = [[KODRegistrationViewController alloc] initWithDelegate:self];

  // Create a navigation controller with the registration view controller as its root view controller
  UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:registrationViewController];

  // Show the navigation controller (as a modal)
  [self presentViewController:navigationController
                     animated:YES
                   completion:nil];
}
```

There are a couple of things that are worth pointing out in the code above:

- To properly initialize the registration view, you need to supply it with a delegate that it will use to notify you of various important events. Having changed the hosting view controller to conform to said protocol we can supply it as the delegate, which is the approach we recommend.
- We display the registration view by making it part of a navigation view controller. This is the recommended way to display the registration view, and will give users the option to back out of the registration process.

This is really all there is to displaying the registration view.

###Interacting with the view
Displaying the view is great, but will only get you so far. It is important to know how our users interact with the view and to that end the view dispatches events to a delegate supplied during its initialization.

<a name="kod_registration_view_controller_delegate"></a>
####The KODRegistrationViewControllerDelegate protocol
The registration view expects its delegate to conform to this protocol, which exposes three different types of callbacks:

1. Registration complete - the user successfully completed the registration process, and has been assigned a token that you can use to place orders on the user's behalf.
2. Registration cancelled - the user chose to back out of the registration process.
3. Registration failed - an error of some sort has prevented the user from successfully going through the registration process.

Building upon the code sample from the previous section, consider the following methods which make a view controller conform to the KODRegistrationViewControllerDelegate protocol. The methods correspond to the types of callbacks we have just listed:

```objective-c
- (void)klarnaRegistrationController:(KODRegistrationViewController *)controller finishedWithResult:(KODRegistrationResult *)registrationResult {
  // Dismiss the registration view and store the user's token
  [self dismissViewControllerAnimated:YES completion:nil];
  [self saveUserToken: registrationResult.token]; // this is for illustrative purposes, we do not supply this method
}

- (void)klarnaRegistrationCancelled:(KODRegistrationViewController *)controller {
  // Dismiss the registration view
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)klarnaRegistrationFailed:(KODRegistrationViewController *)controller {
  // Dismiss Klarna registration view and notify the user of the error
  [self dismissViewControllerAnimated:YES completion:nil];
  [self notifyRegistrationFailed]; // Again, this is just an illustration
}

```

As you can see, your first order of business will usually be to dismiss the registration view upon any of the events occurring. Then, depending on the event, you will want to take further action such as storing the user token or displaying an error message.

<a name="when_to_show_registration"></a>
###When should you show the registration view?
While we've seen how to utilize the registration view, we never talked about **when** you should display it. Our recommendation is to display the registration view when you do not have a user token stored. Assuming your user has gone through the registration process successfully and received a token there is no need to have the user register again, as tokens do not expire (though they can be revoked).

##Performing purchases
The aim of this SDK is to allow users to make purchases using your application, backed by Klarna as a payment method. However, the SDK does not offer any direct methods for performing purchases as this will expose your application's private Klarna credentials. Instead, applications using the SDK are expected to work with an application backend, which will perform the actual purchase requests.

In this section, we will see how to communicate with such a backend and for that purpose we supply a sample backend that you can find [here](https://github.com/klarna/sample-ondemand-backend). Reading the sample backend's documentation will allow you to fully grasp how an application using this SDK is expected to perform purchases, and you are encouraged to take a look if things become too unclear.

###Purchase example
To perform a purchase, you must first sign it (more about this [later](#signing_requests)). Include the following header in your code:

```objective-c
#import "KODOriginProof.h"
```

You will most likely have a "buy" button somewhere in your application. The code below shows how such a button might be implemented in your application's controller:

```objective-c
- (IBAction)onBuyPressed:(id)sender {
  // create an origin proof to secure the purchase. Assume the user token is available in
  // the storedToken variable.
  KODOriginProof *originProof = [[KODOriginProof alloc] initWithAmount:9900
                                                              currency:@"SEK"
                                                             userToken:storedToken];

  // send the purchase request to the backend
  AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
  manager.requestSerializer = [AFJSONRequestSerializer serializer];

  NSDictionary *params = @{
    @"origin_proof" : [originProof description],
    @"reference" :    @"TCKT0001",
    @"user_token" :   storedToken
  };

  [manager POST:@"http://localhost:9292/pay" parameters:params
        success:^(AFHTTPRequestOperation *operation, id responseObject) {
          // The purchase was successful!
        }
        failure:^(AFHTTPRequestOperation *operation, NSError *error) {
          // Something bad happened
        }
  ];
}
```

Note that the code above utilizes the [AFNetworking](http://afnetworking.com/) framework, so you would need to add the `AFNetworking` pod to your podfile and import the `AFHTTPRequestOperationManager.h` header for everything to work.

All the code above does is send the following JSON to `http://localhost:9292/pay` (where the sample backend expects purchase requests when run locally):

```json
{
  "origin_proof":"eyJkYXRhIjoie1wiYW1vdW50XCI6OTkwMCxcImN1cnJlbmN5",
  "reference":"TCKT0001",
  "user_token":"c4efa3a2-3c02-4544-9259-720285788f60"
}
```

This JSON contains the data required for the sample backend to know which purchase request to issue. The `reference` identifies the item to purchase, the `user_token` identifies the user for whom to perform the purchase and the `origin_proof` proves that the request originated from the user's device. Note how we sent a string representation of `originProof` by calling its `description` method.

Remember that if you try this out for yourself, your origin proof and user token will obviously be different. Also note the placeholder comments in the "success" and "failure" blocks above, where you will most likely want to notify the user of the purchase attempt's outcome.

This is really all there is to performing a purchase, though as previously mentioned you will want to take a look at the [sample backend](https://github.com/klarna/sample-ondemand-backend) to get the full picture.

<a name="signing_requests"></a>
###Signing requests
While you can, and almost certainly will, communicate with your application's backend in a way that is different from the very simplistic approach we present here, one thing you will always have to do is sign your purchase requests. This will significantly increase your user's security while buying and the SDK makes this task incredibly easy.

Let us say a user wants to make a purchase for a total of 40.50 Euros. All that's necessary to generate the relevant signature is to perform the method call below:

```objective-c
KODOriginProof *originProof = [[KODOriginProof alloc] initWithAmount:4050
                                                            currency:@"EUR"
                                                           userToken:storedToken];
```

Assume `storedToken` contains the user's token as received during registration. Note that the method expects the purchase amount to be supplied in cents. You can find the method's full documentation [here](http://cocoadocs.org/docsets/Klarna-on-Demand/1.0.3/Classes/KODOriginProof.html#//api/name/initWithAmount:currency:userToken:).

##The preferences view
After having registered to pay using Klarna, users may wish to view or even alter their payment settings (for example, users may wish to switch from using a credit card to monthly invoice payments). As was the case with registration, the SDK provides a view for this purpose. Using the user token acquired during the registration process, you will be able to present your users with a preferences view.

**Note:** It is important to point out that the preferences view will not function properly without network access, and that it does not currently support a landscape orientation. Also, a user's token will remain constant regardless of any preference changes.

###Showing the view
It is good practice to allow users to access the preferences view on demand. Let's see how to set up a button that launches the preferences view.

First, import the preferences view's header file into your view controller:

```objective-c
#import "KODPreferencesViewController.h"
```

Then, declare that your view controller conforms to the KODPreferencesViewControllerDelegate protocol which we will talk about [soon](#kod_preferences_view_controller_delegate). If we were to use the same view controller from when we set up the [registration view](#registration_view), we would go about this by declaring it like so:

```objective-c
@interface MainViewController : UIViewController<KODRegistrationViewControllerDelegate, KODPreferencesViewControllerDelegate>
// Various interface definitions
@end
```

Finally, assuming the button's touch handler is called `onPreferencesPressed`, set it up in the following manner:

```objective-c
- (IBAction)onPreferencesPressed:(id)sender {
  // Create a new Klarna preferences view controller
  KODPreferencesViewController *preferencesViewController = [[KODPreferencesViewController alloc] initWithDelegate:self andToken:storedToken];

  // Create a navigation controller with the preferences view controller as its root view controller
  UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:preferencesViewController];

  // Show the navigation controller (as a modal)
  [self presentViewController:navigationController
                     animated:YES
                   completion:nil];
}
```

There are a few things that are worth pointing out in the code above:

- To properly initialize the preferences view, you need to supply it with the following:
 - A delegate that it will use to notify you of various important events, similar to what we had in the registration view. The code follows the recommended approach, where we supply the hosting view controller that should conform to said protocol.
 - The user token obtained during the user's registration. Assume this token was stored in `storedToken` used above.
- We display the preferences view by making it part of a navigation view controller. This is the recommended way to display the preferences view, as it allows users to close the preferences view and return to your application.

This is all it takes to display the preferences view.

###Interacting with the view
Klarna's payment preferences are managed internally by the SDK so you don't need to worry about them. However, your application needs to know when the user is finished with the preferences view, or if an error occurred. To make this possible, the view dispatches events to the delegate supplied during its initialization.

<a name="kod_preferences_view_controller_delegate"></a>
####The KODPreferencesViewControllerDelegate protocol
The preferences view expects its delegate to conform to this protocol, which exposes two different types of callbacks:

1. Preferences closed - the user actively requested to close the preferences view.
2. Preference operation failed - an error of some sort has prevented the user from successfully using the preferences view.

Building upon the code sample from the previous section, consider the following methods which make a view controller conform to the KODPreferencesViewControllerDelegate protocol. The methods correspond to the types of callbacks we have just listed:

```objective-c
- (void)klarnaPreferencesClosed:(KODPreferencesViewController *)controller {
  // Dismiss the preferences view
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)klarnaPreferencesFailed:(KODPreferencesViewController *)controller {
  // Dismiss the preferences view and notify the user that an error occurred
  [self dismissViewControllerAnimated:YES completion:nil];
  [self notifyOfPreferencesError]; // This method is an illustration and is not part of the SDK
}

```

As you can see, your first order of business will usually be to dismiss the preferences view upon any of the events occurring. In case of an error, you are strongly encouraged to notify the user as most errors are unrecoverable and require the preferences view to be reopened.
