import UIKit
import PassKit
import SkipCashSDK
import Foundation
import WebKit

public class PaymentData: NSObject, Codable{
    let merchantIdentifier: String
    let countryCode: String
    let currencyCode: String
    let createPaymentLinkEndPoint: String
    let authorizationHeader: String
    let amount: String
    let firstName: String
    let lastName: String
    let phone: String
    let email: String
    let summaryItems: [String: String]

    init?(data: [String: Any]) {
        guard
            let merchantIdentifier = data["merchantIdentifier"] as? String,
            let countryCode = data["countryCode"] as? String,
            let currencyCode = data["currencyCode"] as? String,
            let createPaymentLinkEndPoint = data["createPaymentLinkEndPoint"] as? String,
            let authorizationHeader = data["authorizationHeader"] as? String,
            let amount = data["amount"] as? String,
            let firstName = data["firstName"] as? String,
            let lastName = data["lastName"] as? String,
            let phone = data["phone"] as? String,
            let email = data["email"] as? String,
            let summaryItems = data["summaryItems"] as? [String: String]
        else {
            return nil
        }

        self.merchantIdentifier = merchantIdentifier
        self.countryCode = countryCode
        self.currencyCode = currencyCode
        self.createPaymentLinkEndPoint = createPaymentLinkEndPoint
        self.authorizationHeader = authorizationHeader
        self.amount = amount
        self.firstName = firstName
        self.lastName = lastName
        self.phone = phone
        self.email = email
        self.summaryItems = summaryItems
    }
}


@objc public class ScApplePay: NSObject, ApplePayReponseDelegate {
    private var paymentData: PaymentData?
    let webConfiguration = WKWebViewConfiguration()
    var webView: WKWebView!
    var navigationController: UINavigationController?
    var returnURL: String?
    
    public func applePayResponseData(paymentId: String, isSuccess: Bool, token: String, returnCode: Int, errorMessage: String) {

        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
            let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            
        return
        }

        var viewController = window.rootViewController
        while let presentedViewController = viewController?.presentedViewController {
        viewController = presentedViewController
        }
        
        viewController?.dismiss(animated: true, completion: nil)

        let responseData: [String: Any] = [
        "paymentId": paymentId,
        "isSuccess": isSuccess,
        "token": token,
        "returnCode": returnCode,
        "errorMessage": errorMessage
        ]

        let  eventEmitter  =   ScApplePayPlugin()
        
//        eventEmitter.sendEventToJs(responseData)

        // sendEvent(withName: "applepay_response", body: responseData)
    }

    @IBOutlet weak var applePayView: UIView!
    var paymentController: PKPaymentAuthorizationController?
    var paymentSummaryItems = [PKPaymentSummaryItem]()
    var paymentStatus = PKPaymentAuthorizationStatus.failure
    typealias PaymentCompletionHandler = (Bool) -> Void
    var completionHandler: PaymentCompletionHandler!

    static let supportedNetworks: [PKPaymentNetwork] = [
        .amex,
        .discover,
        .masterCard,
        .visa
    ]

    @objc(isWalletHasCards)
    func isWalletHasCards () -> Bool {
        let result = ScApplePay.applePayStatus();
    
        return result.canMakePayments;
    }

    @objc(setupNewCard)
    func setupNewCard() {
        let passLibrary = PKPassLibrary()
        passLibrary.openPaymentSetup()
    }

    class func applePayStatus() -> (canMakePayments: Bool, canSetupCards: Bool) {
    return (PKPaymentAuthorizationController.canMakePayments(),
            PKPaymentAuthorizationController.canMakePayments(usingNetworks: supportedNetworks))
    }

    func convertToDecimal(with string: String) -> NSDecimalNumber {
        let formatter = NumberFormatter()
        formatter.decimalSeparator = "."
        formatter.generatesDecimalNumbers = true
        formatter.maximumFractionDigits = 2
        
        if let number = formatter.number(from: string) as? NSDecimalNumber {
            return number
        } else {
            return 0
        }
    }

    @objc func initiatePayment(jsonString: String){
      if let jsonData = jsonString.data(using: .utf8) {
       do {
               // Convert JSON data to a dictionary
           if let paymentDictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
              if let paymentData = PaymentData(data: paymentDictionary) {
                  self.startPayment(data: paymentData){
                       (success) in
                           if success {
//                               print("Success")
                           }else {
//                               print("Failur")
                           }
                       }
                   } else {
                       print("Error: Unable to initialize PaymentData object")
                   }
               } else {
                   print("Error: Unable to parse JSON data into dictionary")
               }
           } catch {
               print("Error: \(error)")
           }
       } else {
           print("Error: Unable to convert JSON string to data")
       }
    }


    func startPayment(data: PaymentData, completion: @escaping PaymentCompletionHandler) {
            
        completionHandler = completion
        
        paymentData = data
        
        var paymentSummaryItems = [PKPaymentSummaryItem]()

        for (label, amountString) in data.summaryItems {
            guard let amount = Decimal(string: amountString) else {
                // Handle invalid amount string
                print("Invalid amount string: \(amountString)")
                continue
            }

            // Successfully converted, create a PKPaymentSummaryItem and append it
            let paymentItem = PKPaymentSummaryItem(label: label, amount: NSDecimalNumber(decimal: amount))
            paymentSummaryItems.append(paymentItem)
        }
        
        
        let totalAmount = convertToDecimal(with: data.amount)
        
        let totalAmountItem = PKPaymentSummaryItem(label: "Total", amount: totalAmount)
        paymentSummaryItems.append(totalAmountItem)


        let paymentRequest = PKPaymentRequest()

        paymentRequest.paymentSummaryItems = paymentSummaryItems
        paymentRequest.merchantIdentifier   = data.merchantIdentifier
        paymentRequest.merchantCapabilities = .threeDSecure
        paymentRequest.countryCode          = data.countryCode
        paymentRequest.currencyCode         = data.currencyCode
        paymentRequest.supportedNetworks    = ScApplePay.supportedNetworks

        let paymentController = PKPaymentAuthorizationController(paymentRequest: paymentRequest)
        
        paymentController.delegate = self
        
        paymentController.present(completion: { (presented: Bool) in
            if presented {
                debugPrint("Presented payment controller")
            } else {
                debugPrint("Failed to present payment controller")
                self.completionHandler(false)
            }
        })
    }
}


extension ScApplePay: PKPaymentAuthorizationControllerDelegate {

  public func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {

    let errors = [Error]()
    let status = PKPaymentAuthorizationStatus.success

    var sign = ""
    
    do {
        if let jsonResponse = try JSONSerialization.jsonObject(with: payment.token.paymentData, options: []) as? [String: Any] {
            sign = String(decoding: payment.token.paymentData, as: UTF8.self)
        } else {
            print("error")
        }
    } catch {
        print("error converting payment token")
    }

   let podBundle  = Bundle(for: SetupVC.self)

    let customer_data = CustomerPaymentData(
        phone: self.paymentData!.phone,
        email: self.paymentData!.email,
        firstName: self.paymentData!.firstName,
        lastName: self.paymentData!.lastName,
        amount: self.paymentData!.amount
    )

    let storyboard = UIStoryboard(name: "main", bundle: podBundle)

    if let vc = storyboard.instantiateViewController(withIdentifier: "SetupVC") as? SetupVC,
      let topViewController = UIApplication.shared.keyWindow?.rootViewController?.topMostViewController(){
      vc.modalPresentationStyle = .overCurrentContext
      vc.paymentData = customer_data
      vc.appBackendServerEndPoint = self.paymentData!.createPaymentLinkEndPoint
      
      if !self.paymentData!.authorizationHeader.isEmpty {
          vc.authorizationHeader      = self.paymentData!.authorizationHeader
      }else{
          vc.authorizationHeader = ""
      }
      
      vc.delegate = self
      vc.paymentToken = sign
      topViewController.modalPresentationStyle = .overCurrentContext
      topViewController.present(vc, animated: true, completion: nil)
    }

      let vc = SetupVC()

      // Set properties of vc
      vc.modalPresentationStyle = .overCurrentContext
      vc.paymentData = customer_data
      vc.appBackendServerEndPoint = self.paymentData!.createPaymentLinkEndPoint

      if !self.paymentData!.authorizationHeader.isEmpty {
        vc.authorizationHeader = self.paymentData!.authorizationHeader
      } else {
        vc.authorizationHeader = ""
      }

      vc.delegate = self
      vc.paymentToken = sign

      if let topViewController = UIApplication.shared.keyWindow?.rootViewController?.topMostViewController() {
        // Present vc
        topViewController.modalPresentationStyle = .overCurrentContext
        topViewController.present(vc, animated: true, completion: nil)
      }

      self.paymentStatus = status
      completion(PKPaymentAuthorizationResult(status: status, errors: errors))
  }

  public func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
    controller.dismiss {
    // dismiss the payment sheet
      DispatchQueue.main.async {
        if self.paymentStatus == .success {
          self.completionHandler!(true)
        } else {
          self.completionHandler!(false)
        }
      }
    }
  }
}

class CustomPresentationController: UIPresentationController {
    override var shouldRemovePresentersView: Bool {
        return false
    }

    override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)
        if completed {
            presentedViewController.view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:))))
        }
    }

    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        // Prevent dismissal by dragging down
    }
}


extension ScApplePay: WKNavigationDelegate {
  
    // Your other methods...

    @objc func loadSCPGW(url: String, paymentTitle: String, returnURL: String) {
        DispatchQueue.main.async {
            self.returnURL = returnURL
            
            if let topViewController = UIApplication.shared.keyWindow?.rootViewController?.topMostViewController() {
                
                self.webView = WKWebView(frame: .zero, configuration: self.webConfiguration)
                self.webView.navigationDelegate = self // Set the navigation delegate to self
                
                if let myURL = URL(string: url) {
                    let myRequest = URLRequest(url: myURL)
                    self.webView.load(myRequest)
                } else {
                    print("Invalid URL: \(url)")
                }
                
                let webViewController = UIViewController()
                webViewController.view.addSubview(self.webView)
                self.webView.frame = webViewController.view.bounds
                self.webView.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50,right:0)

                
                let navigationBar = UINavigationBar(frame: CGRect(x: 0, y: UIApplication.shared.statusBarFrame.height, width: UIScreen.main.bounds.width, height: 50))
                let navigationItem = UINavigationItem()
                navigationItem.title = paymentTitle
                let backButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.goBack))
                navigationItem.leftBarButtonItem = backButton
                navigationBar.setItems([navigationItem], animated: false)
                webViewController.view.addSubview(navigationBar)
                
                if let navigationController = topViewController.navigationController {
                    navigationController.modalPresentationStyle = .popover
                    navigationController.isModalInPresentation = true
                    navigationController.pushViewController(webViewController, animated: true)
                } else {
                    let navigationController = UINavigationController(rootViewController: webViewController)
                    navigationController.modalPresentationStyle = .popover
                    navigationController.isModalInPresentation = true
                    topViewController.present(navigationController, animated: true, completion: nil)
                }
            } else {
                print("Unable to find top view controller")
            }
        }
    }

    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if let currentURL = webView.url {
            if currentURL.absoluteString.range(of: self.returnURL!, options: .caseInsensitive) != nil {
                goBack()
            }
        }
    }
    
    @objc func goBack() {
        DispatchQueue.main.async {
            if let topViewController = UIApplication.shared.keyWindow?.rootViewController?.topMostViewController() {
                topViewController.dismiss(animated: true, completion: nil)
            } else {
                debugPrint("Unable to find top view controller")
            }
        }
    }

}

extension UIViewController {
  func topMostViewController() -> UIViewController {
    if let presentedViewController = presentedViewController {
        presentedViewController.modalPresentationStyle = .overCurrentContext
        return presentedViewController.topMostViewController()
    }
    if let navigationController = self as? UINavigationController {
        navigationController.modalPresentationStyle = .overCurrentContext
        return navigationController.visibleViewController?.topMostViewController() ?? navigationController
    }
    if let tabBarController = self as? UITabBarController {
        tabBarController.modalPresentationStyle = .overCurrentContext
        return tabBarController.selectedViewController?.topMostViewController() ?? tabBarController
    }
    self.modalPresentationStyle = .overCurrentContext
    return self
  }
}
