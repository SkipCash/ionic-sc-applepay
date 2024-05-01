
import Foundation
import Capacitor

@objc(ScApplePayPlugin)
public class ScApplePayPlugin: CAPPlugin {
    
    private let implementation = ScApplePay()

    func paymentFinished(){
        self.notifyListeners("payment_finished_webview_closed", data: nil)
    }


    // func sendEventToJs(dataString: [String: Any]){
    //     self.notifyListeners("applepay_response", data: dataString)


    // }

    // @objc func initiatePayment(_ call: CAPPluginCall) {
    //     let value = call.getString("paymentData") ?? ""

    //     implementation.initiatePayment(jsonString: value)
    // }
    
    // @objc func isWalletHasCards(_ call: CAPPluginCall) {
    //     let result = implementation.isWalletHasCards()
        
    //     call.resolve([
    //         "value": result
    //     ])
    // }
    
    @objc func loadSCPGW(_ call: CAPPluginCall) {
        let payUrl       = call.getString("payUrl") ?? ""
        let paymentTitle = call.getString("paymentTitle") ?? "Payment"
        let returnURL    = call.getString("returnURL") ?? ""
        
        if(payUrl.isEmpty && returnURL.isEmpty){
            debugPrint("Please provide both payUrl and returnURL")
        }else{
            implementation.loadSCPGW(url: payUrl, paymentTitle: paymentTitle, returnURL: returnURL)
        }
        
    }

    // @objc func setupNewCard(_ call: CAPPluginCall) {
    //     implementation.setupNewCard()
    // }

}

