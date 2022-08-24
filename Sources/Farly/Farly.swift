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

@objc public enum HostedOfferwallPresentationMode: Int {
    case webView
    case browser
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
    
    @objc public var apiDomain: String = "www.mob4pass.com"
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
        
        var params: [String : String?] = [
            "pubid" : publisherId,
            "timestamp" : timestamp,
            "hash" : hash,
            "userid" : request.userId,
            "device" : OfferWallParametersUtils.getCurrentDevice().rawValue,
            "devicemodel": OfferWallParametersUtils.getDeviceModelCode(),
            "os_version": UIDevice.current.systemVersion,
            "is_tablet": OfferWallParametersUtils.getCurrentDevice() == .iPad ? "1" : "0",
            "country": locale.regionCode,
            "locale": locale.identifier.starts(with: "fr") ? "fr" : "en",
            "zip": request.zipCode,
            "carrier": OfferWallParametersUtils.getCarrierCode()
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
        
        return url.url!
    }
    
    /// Return a formatted URL, ready to be used in a webview or browser
    @objc
    public func getHostedOfferwallUrl(request: OfferWallRequest) -> URL? {
        do {
            return try getParameterizedUrl(request: request, endpoint: .hostedWall)
        } catch MessageError.error(let message) {
            print("Error: \(message)")
        } catch let e {
            print("Error: \(e)")
        }
        return nil
    }
    
    private var presentedNavigationViewController: UINavigationController?
    
    /// Show the hosted Offerwall in webview or in browser
    @objc
    public func showOfferwall(request: OfferWallRequest, mode: HostedOfferwallPresentationMode) {
        do {
            let url = try getParameterizedUrl(request: request, endpoint: .hostedWall)
            
            switch mode {
            case .browser:
                if !UIApplication.shared.canOpenURL(url){
                    throw MessageError.error(message: "Cannot open url")
                }
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url)
                } else {
                    UIApplication.shared.openURL(url)
                }
                break
            case .webView:
                guard let viewController = UIApplication.shared.windows.first?.rootViewController else {
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

                viewController.present(navVC, animated: true, completion: nil)
                break
            }
        } catch MessageError.error(let message) {
            print("Error: \(message)")
        } catch let e {
            print("Error: \(e)")
        }
        return
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
            print("Calling Offerwall : \(url)")
            print("###################")
#endif
            
            var request = URLRequest(url: url, timeoutInterval: 30)
            request.httpMethod = "GET"
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data else {
                    print("ERROR" + String(describing: error))
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
            print("Error: \(message)")
            completion(message, nil)
        } catch let e {
            print("Error: \(e)")
            completion("An unknown error ocured", nil)
        }
    }
}
