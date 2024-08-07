import UIKit
import PassKit
import SkipCashSDK
import Foundation
import WebKit
import Capacitor

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
    private var scApplePlugin: ScApplePayPlugin?
    private var eventSent = false
    let webConfiguration = WKWebViewConfiguration()
    var webView: WKWebView!
    var navigationController: UINavigationController?
    var returnURL: String?
    private var paymentID: String = ""
    private var transactionID: String = ""
    
    public func applePayResponseData(transactionID: String, paymentID: String, isSuccess: Bool, token: String, returnCode: Int, errorMessage: String, completion: ((PKPaymentAuthorizationResult) -> Void)?) {
        
        
        if !eventSent{
            eventSent = true

            let responseData: [String: Any] = [
                "transactionId": transactionID,
                "paymentId": paymentID,
                "isSuccess": isSuccess,
                "token": token,
                "returnCode": returnCode,
                "errorMessage": errorMessage
            ]

            if (isSuccess) {
                let errors = [Error]()
                let status = PKPaymentAuthorizationStatus.success
                self.paymentStatus = status
                completion?(PKPaymentAuthorizationResult(status: status, errors: errors))
            }else{
                let errors = [Error]()
                let status = PKPaymentAuthorizationStatus.failure
                completion?(PKPaymentAuthorizationResult(status: status, errors: errors))
            }
            
            self.scApplePlugin?.applePayResponse(applePayResponse: responseData)
        }

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

    func getPaymentID(authorizationHeader: String, data: [String: Any], createPaymentApi: String, completion: @escaping (String?) -> Void) {
        
        var convertedData: [String: Any] = [:]
        
        convertedData["Amount"]          = data["amount"]
        convertedData["FirstName"]       = data["firstName"]
        convertedData["LastName"]        = data["lastName"]
        convertedData["Phone"]           = data["phone"]
        convertedData["Email"]           = data["email"]
        

        if let transactionId = data["transactionId"] as? String, !transactionId.isEmpty {
            convertedData["TransactionId"] = transactionId
            self.transactionID = transactionId
        }else{
            self.transactionID = ""
        }

        if let webhookUrl = data["webhookUrl"] as? String, !webhookUrl.isEmpty {
            convertedData["webhookUrl"] = data["webhookUrl"]
        }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: convertedData) else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: URL(string: createPaymentApi)!, timeoutInterval: 30)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if authorizationHeader.count > 0 {
            request.addValue(authorizationHeader, forHTTPHeaderField: "Authorization")
        }
        
        request.httpMethod = "POST"
        request.httpBody = jsonData
    
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                if let error = error {
                    debugPrint("Error: \(error.localizedDescription)")
                    let responseData: [String: Any] = [
                        "transactionId": "",
                        "paymentId": "",
                        "isSuccess": false,
                        "token": "",
                        "returnCode": 400,
                        "errorMessage": "\(error.localizedDescription)"
                    ]
                    
                    self.scApplePlugin?.applePayResponse(applePayResponse: responseData)

                    completion(nil)
                    return
                }
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                if let tempResponse = json as? [String: Any],
                   let responseObj = tempResponse["resultObj"] as? [String: Any],
                   let paymentID = responseObj["id"] as? String {
                    completion(paymentID)
                    return
                }
            } catch {
                debugPrint("Error: \(error.localizedDescription)")
                let responseData: [String: Any] = [
                    "transactionId": "",
                    "paymentId": "",
                    "isSuccess": false,
                    "token": "",
                    "returnCode": 400,
                    "errorMessage": "\(error.localizedDescription)"
                ]
                
                self.scApplePlugin?.applePayResponse(applePayResponse: responseData)
                completion(nil)
                return
            }
        }
        
        task.resume()
    }

    @objc func initiatePayment(ob: ScApplePayPlugin, jsonString: String){
        eventSent = false
        scApplePlugin = ob
      if let jsonData = jsonString.data(using: .utf8) {
       do {
               // Convert JSON data to a dictionary
           if let paymentDictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
              if let paymentData = PaymentData(data: paymentDictionary) {
                  getPaymentID(authorizationHeader: paymentData.authorizationHeader, data: paymentDictionary, createPaymentApi: paymentData.createPaymentLinkEndPoint) { paymentID in
                      guard let paymentID = paymentID else {
                          // handle error event
                          debugPrint("Failed to get new payment ID")
                          
                          return
                      }
                      self.startPayment(data: paymentData, paymentID: paymentID){ success in
                          if success {
                              //                               print("Success")
                          }else {
                              //                               print("Failed")
                          }
                      }
                    }
                  } else {
                      debugPrint("Error: Unable to initialize PaymentData object")
                  }
               } else {
                   debugPrint("Error: Unable to parse JSON data into dictionary")
               }
           } catch {
               debugPrint("Error: \(error)")
           }
       } else {
           debugPrint("Error: Unable to convert JSON string to data")
       }
    }


    func startPayment(data: PaymentData,  paymentID: String, completion: @escaping PaymentCompletionHandler) {
            
        completionHandler = completion
        
        paymentData = data
        
        self.paymentID = paymentID
        
        var paymentSummaryItems = [PKPaymentSummaryItem]()

        for (label, amountString) in data.summaryItems {
            guard let amount = Decimal(string: amountString) else {
                // Handle invalid amount string
                debugPrint("Invalid amount string: \(amountString)")
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

      var token = ""
      
      do {
        if let jsonResponse = try JSONSerialization.jsonObject(with: payment.token.paymentData, options: []) as? [String: Any] {
            token = String(decoding: payment.token.paymentData, as: UTF8.self)
        } else {
           debugPrint("Failed to get applepay token")
            

           let errors = [Error]()
           let status = PKPaymentAuthorizationStatus.failure
           
           self.paymentStatus = status
           completion(PKPaymentAuthorizationResult(status: status, errors: errors))
            
            let responseData: [String: Any] = [
                 "transactionId": "",
                 "paymentId": "",
                 "isSuccess": false,
                 "token": "",
                 "returnCode": 400,
                 "errorMessage": "Failed to get applepay token"
             ]
             
             self.scApplePlugin?.applePayResponse(applePayResponse: responseData)
        }
      } catch {
        debugPrint("error converting payment token")

        let errors = [Error]()
        let status = PKPaymentAuthorizationStatus.failure
        
        self.paymentStatus = status
        completion(PKPaymentAuthorizationResult(status: status, errors: errors))
      }

      let podBundle  = Bundle(for: SetupVC.self)


      let storyboard = UIStoryboard(name: "main", bundle: podBundle)

      let vc = SetupVC()
      
      vc.modalPresentationStyle = .overCurrentContext
      vc.delegate               = self
      vc.transactionId          = self.transactionID
      vc.paymentID              = self.paymentID
      vc.completion             = completion
      vc.paymentToken           = token

      if let topViewController = UIApplication.shared.keyWindow?.rootViewController?.topMostViewController() {
          topViewController.modalPresentationStyle = .overCurrentContext
          topViewController.present(vc, animated: true, completion: nil)
      }
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
  
    @objc func loadSCPGW(url: String, paymentTitle: String, returnURL: String, pluginInstance :ScApplePayPlugin) {
        scApplePlugin = pluginInstance
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
                self.scApplePlugin?.paymentFinished()
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
