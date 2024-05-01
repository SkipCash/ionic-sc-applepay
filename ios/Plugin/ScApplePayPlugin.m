#import <Foundation/Foundation.h>
#import <Capacitor/Capacitor.h>

// Define the plugin using the CAP_PLUGIN Macro, and
// each method the plugin supports using the CAP_PLUGIN_METHOD macro.
CAP_PLUGIN(ScApplePayPlugin, "ScApplePay",
           CAP_PLUGIN_METHOD(initiatePayment, CAPPluginReturnNone);
           CAP_PLUGIN_METHOD(isWalletHasCards, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(setupNewCard, CAPPluginReturnNone);
           CAP_PLUGIN_METHOD(loadSCPGW, CAPPluginReturnNone);
)
