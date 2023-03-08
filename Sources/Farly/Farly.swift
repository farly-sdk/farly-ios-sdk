import UIKit
import WebKit
import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@objc public enum Gender: Int {
    case Male
    case Female
    case Unknown
}

enum Endpoint: String {
    case apiFeedV2 = "/api/feed/v2"
    case hostedWall = "/offers"
}

@objc
public class OfferWallRequest: NSObject {
    /// Your unique id for the current user
    @objc public var userId: String
    
    /// Current zipCode of the user, should be fetched from geolocation, not from geoip
    @objc public var zipCode: String?
    
    /// Current 2 letters country code of the user, if not provided will default to the user's preferred region
    @objc public var countryCode: String?
    
    /// Your user's age
    @objc public var userAge: NSNumber?
    
    /// Gender of the user, to access targetted campaigns
    @objc public var userGender: Gender = .Unknown
    
    /// Date at which your user did signup
    @objc public var userSignupDate: Date?
    
    /// parameters you wish to get back in your callback
    @objc public var callbackParameters: [String] = []
    
    @objc
    public init(userId: String) {
        self.userId = userId
    }
}

enum MessageError: Error {
    case error(message: String)
}

@objc
public class Farly: NSObject {
    
    @objc public static let shared = Farly()
    
    @objc public var apiKey: String?
    @objc public var publisherId: String?
    
    @objc public var apiDomain: String = "www.farly.io"
    @objc public var offerwallDomain: String = "offerwall.farly.io"
    
    private override init() {}
    
    func getParameterizedUrl(request: OfferWallRequest, endpoint: Endpoint) throws -> URL {
        guard let publisherId = self.publisherId, let apiKey = self.apiKey else {
            let error = "🛑 Farly needs to be configured with an apiKey and publisherId before being called"
            throw MessageError.error(message: error)
        }
        
        var url = URLComponents(string: "https://\(endpoint == .hostedWall ? self.offerwallDomain : self.apiDomain)\(endpoint.rawValue)")!
        
        let cleanNumberFormatter = NumberFormatter()
        cleanNumberFormatter.allowsFloats = false
        
        let timestamp = cleanNumberFormatter.string(from: Date().timeIntervalSince1970 as NSNumber)!
        guard let hash = "\(timestamp)\(apiKey)".data(using: .utf8)?.sha1 else {
            throw MessageError.error(message: "FATAL: Unable to compute hash")
        }
        
        let locale = OfferWallParametersUtils.getLocale()
        let country = request.countryCode ?? OfferWallParametersUtils.getCountryCode()
        
        if country == nil {
            print("###################")
            print("## FARLY - Country could not be found in the devices preferred region, please pass it in the request country parameter")
            print("###################")
        }
        
        var params: [String : String?] = [
            "pubid" : publisherId,
            "timestamp" : timestamp,
            "hash" : hash,
            "userid" : request.userId,
            "device" : OfferWallParametersUtils.getCurrentDevice().rawValue,
            "devicemodel": OfferWallParametersUtils.getDeviceModelCode(),
            "os_version": UIDevice.current.systemVersion,
            "is_tablet": OfferWallParametersUtils.getCurrentDevice() == .iPad ? "1" : "0",
            "country": country,
            "locale": locale.identifier.starts(with: "fr") ? "fr" : "en",
            "zip": request.zipCode,
            "carrier": OfferWallParametersUtils.getCarrierCode(),
            "from": "wallv2"
        ]
        
        if request.userGender == .Male {
            params["user_gender"] = "m"
        } else if request.userGender == .Female {
            params["user_gender"] = "f"
        }
        
        if let userAge = request.userAge {
            params["user_age"] = cleanNumberFormatter.string(from: userAge)
        }
        
        if let signupTimestamp = request.userSignupDate?.timeIntervalSince1970 {
            params["user_signup_timestamp"] = cleanNumberFormatter.string(from: signupTimestamp as NSNumber)
        }
        
        if let idfa = OfferWallParametersUtils.getIDFA() {
            params["idfa"] = idfa
            params["idfasha1"] = idfa.data(using: .utf8)?.sha1
        }
        
        for i in 0..<request.callbackParameters.count {
            let param = request.callbackParameters[i]
            params["pub\(i)"] = param
        }
        
        var items: [URLQueryItem] = []
        for (key, value) in params {
            if let value = value {
                items.append(URLQueryItem(name: key, value: value))
            }
        }
        url.queryItems = items
        
        print("## FARLY -  Offerwall URL : \(url.url!)")
        
        return url.url!
    }
    
    /// Return a formatted URL, ready to be used in a webview or browser
    @objc
    public func getHostedOfferwallUrl(request: OfferWallRequest) -> URL? {
        do {
            return try getParameterizedUrl(request: request, endpoint: .hostedWall)
        } catch MessageError.error(let message) {
            print("## FARLY - Error: \(message)")
        } catch let e {
            print("## FARLY - Error: \(e)")
        }
        return nil
    }
    
    private var presentedNavigationViewController: UINavigationController?
    
    /**
     Show the hosted Offerwall in a webview (inside the app).
     - Parameter request: use this to personalize the results for your user
     - Parameter presentingViewController: you can pass your own presentingViewController. If not provided, the SDK tries to use the rootViewController of the app
     - Parameter completion: gets called once the webview is presented, or if an error occurs
     */
    @objc
    public func showOfferwallInWebview(request: OfferWallRequest, presentingViewController: UIViewController? = nil, completion: ((_ error: Error?) -> ())? = nil) {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.showOfferwallInWebview(
                    request: request,
                    presentingViewController: presentingViewController,
                    completion: completion
                )
            }
            return
        }
        do {
            let url = try getParameterizedUrl(request: request, endpoint: .hostedWall)
            
            guard let viewController = presentingViewController ?? UIApplication.shared.windows.first?.rootViewController else {
                throw MessageError.error(message: "No root view controller found")
            }
            
            let webView = WKWebView()
            webView.translatesAutoresizingMaskIntoConstraints = false
            
            let vc = UIViewController()
            vc.view.addSubview(webView)
            vc.view.backgroundColor = UIColor.white
            
            NSLayoutConstraint.activate([
                webView.topAnchor.constraint(equalTo: vc.view.topAnchor),
                webView.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor),
                webView.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor)
            ])
            if #available(iOS 11.0, *) {
                let guide = vc.view.safeAreaLayoutGuide
                NSLayoutConstraint.activate([
                    webView.bottomAnchor.constraint(equalTo: guide.bottomAnchor)
                ])
            } else {
                NSLayoutConstraint.activate([
                    vc.bottomLayoutGuide.topAnchor.constraint(equalTo: webView.bottomAnchor)
                ])
            }
            
            let navVC = UINavigationController(rootViewController: vc)
            
            vc.navigationItem.rightBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .done,
                target: self,
                action: #selector(dismissPresentedViewController)
            )
            
            self.presentedNavigationViewController = navVC
            
            webView.load(URLRequest(url: url))
            viewController.present(navVC, animated: true) {
                completion?(nil)
            }
        } catch let e {
            print("## FARLY - Error: \(e)")
            completion?(e)
            return
        }
    }
    
    /**
     Show the hosted Offerwall in the browser (outside the app).
     - Parameter request: use this to personalize the results for your user
     - Parameter completion: gets called once the url is opened, or if an error occurs
     */
    @objc
    public func showOfferwallInBrowser(request: OfferWallRequest, completion: ((_ error: Error?) -> ())? = nil) {
        do {
            let url = try getParameterizedUrl(request: request, endpoint: .hostedWall)
            if !UIApplication.shared.canOpenURL(url){
                throw MessageError.error(message: "Cannot open url")
            }
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:]) { success in
                    if success {
                        completion?(nil)
                    } else {
                        completion?(MessageError.error(message: "UIApplication.shared.open failed to open url"))
                    }
                }
            } else {
                UIApplication.shared.openURL(url)
                completion?(nil)
            }
        } catch let e {
            print("## FARLY - Error: \(e)")
            completion?(e)
        }
    }
    
    @objc
    func dismissPresentedViewController() {
        self.presentedNavigationViewController?.dismiss(animated: true, completion: nil)
    }
    
    /// Fetch OfferWall
    ///
    /// - Warning: Do NOT use the wall unless you got specific authorization from the user to collect and share those personal data for advertising
    ///
    @objc
    public func getOfferWall(request: OfferWallRequest, completion: @escaping (_ error: String?, _ offers: [FeedElement]?) -> ()) {
        do {
            let url = try self.getParameterizedUrl(request: request, endpoint: .apiFeedV2)
            
#if DEBUG
            print("###################")
            print("## FARLY - Calling Offerwall : \(url)")
            print("###################")
#endif
            
            var request = URLRequest(url: url, timeoutInterval: 30)
            request.httpMethod = "GET"
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data else {
                    print("## FARLY - ERROR" + String(describing: error))
                    completion(String(describing: error), nil)
                    return
                }
                
                guard let elements = try? JSONDecoder().decode(Feed.self, from: data) else {
                    let message = String(data: data, encoding: .utf8)
                    completion("Could not parse feed response: \(String(describing: message))", nil)
                    return
                }
                
                completion(nil, elements)
            }
            
            task.resume()
        } catch MessageError.error(let message) {
            print("## FARLY - Error: \(message)")
            completion(message, nil)
        } catch let e {
            print("## FARLY - Error: \(e)")
            completion("An unknown error ocured", nil)
        }
    }
}
