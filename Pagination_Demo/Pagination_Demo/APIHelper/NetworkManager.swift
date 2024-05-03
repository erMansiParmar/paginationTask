//
//  NetworkManager.swift
//  Tajurba
//
//  Created by BizBrolly on 01/07/23.
//

import Foundation
import Alamofire



class Connectivity {
    class var isConnectedToInternet:Bool {
        return NetworkReachabilityManager()?.isReachable ?? false
    }
}


class NetworkManager {
    static let shared: NetworkManager = {
        return NetworkManager()
    }()
    private var retryLimit = 1
    
    //MARK: ----------------- It's used for array of object as parameter to pass to use codable struct as like struct Example:Codable{ var i = 0 }
    
    func serviceAPICallForArrayObject<T: Encodable>(_ serviceEndPoint: TajurbaEndPoint, method: HTTPMethod, queries: [String: String]? = nil, parametersEncode: [T]? = nil, interceptor: RequestInterceptor? = nil, isShowLoading: Bool = false, completion: @escaping ((Data?, Error?) -> Void)){
        
        let url = serviceEndPoint.getURL(queries: queries)
        let headers = serviceEndPoint.headers
        
        guard let url = url else {
            // Invalid url
            return
        }
        if !Connectivity.isConnectedToInternet{   // no internet connection
            AlertHelper.showAlert(message: kNoInternetConnection)
            completion(nil, nil)
            return
        }
        // Show Loader
        if isShowLoading{
            Utility.showLoader(message: StringConstant.PleaseWait)
        }
        
    
        AF.request(url, method: method, parameters: parametersEncode, encoder: JSONParameterEncoder.default, headers: headers, interceptor: interceptor ?? self).validate().responseData { response in
            Utility.hideLoader() // Dismiss Loader
            switch response.result{
            case .success(_):
                if let statusCode = response.response?.statusCode {
                    switch statusCode {
                    case 200...299:
                        if let data = response.data {
                            do {
                                if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                                    print(json)
                                }
                            }catch {
                                print(error.localizedDescription)
                            }
                            completion(data, nil)
                        }
                    case badRequest:
                        // Bad Request: Handle the specific error case
                        print("Bad Request")
                    case InvalidAccessTokenCode:
                        // Unauthorized: Handle the specific error case
                        self.handle401StatusCode(serviceEndPoint)
                        print("INVALID AUTHTOKEN") //when AuthToken is expire
                        
                    default:
                        print("Status Code: \(statusCode)")
                        break
                    }
                }
                
            case .failure(let error):
                if let statusCode = response.response?.statusCode {
                    switch statusCode {
                    case InvalidAccessTokenCode:
                        self.handle401StatusCode(serviceEndPoint)
                    default:
                        AlertHelper.showAlert(message: error.localizedDescription)
                        completion(nil, nil)
                        break
                    }
                }
            }
        }
        
    }
    
    func genericAPICall(_ serviceEndPoint: TajurbaEndPoint, method: HTTPMethod, queries: [String: String]? = nil, parameters: Parameters? = nil, interceptor: RequestInterceptor? = nil, isShowLoading: Bool = false, completion: @escaping ((Data?, Error?) -> Void)){
        
        let url = serviceEndPoint.getURL(queries: queries)
        let headers = serviceEndPoint.headers
        
        guard let url = url else {
            // Invalid url
            return
        }
        if !Connectivity.isConnectedToInternet{   // no internet connection
            AlertHelper.showAlert(message: kNoInternetConnection)
            completion(nil, nil)
            return
        }
        // Show Loader
        if isShowLoading{
            Utility.showLoader(message: StringConstant.PleaseWait)
        }
        AF.request(url, method: method, parameters: parameters, encoding: JSONEncoding.default, headers: headers, interceptor: interceptor ?? self).validate().responseData{ response in
            Utility.hideLoader() // Dismiss Loader
            switch response.result{
            case .success(_):
                if let statusCode = response.response?.statusCode {
                    switch statusCode {
                    case 200...299:
                        if let data = response.data {
                            do {
                                if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                                    print(json)
                                }
                            }catch {
                                print(error.localizedDescription)
                            }
                            completion(data, nil)
                        }
                    case badRequest:
                        // Bad Request: Handle the specific error case
                        print("Bad Request")
                    case InvalidAccessTokenCode:
                        // Unauthorized: Handle the specific error case
                        self.handle401StatusCode(serviceEndPoint)
                        print("INVALID AUTHTOKEN") //when AuthToken is expire
                        
                    default:
                        print("Status Code: \(statusCode)")
                        break
                    }
                }
                
            case .failure(let error):
                if let statusCode = response.response?.statusCode {
                    switch statusCode {
                    case InvalidAccessTokenCode:
                        self.handle401StatusCode(serviceEndPoint)
                    default:
                        AlertHelper.showAlert(message: error.localizedDescription)
                        completion(nil, nil)
                        break
                    }
                }
            }
        }
    }
    
    private func handle401StatusCode(_ serviceEndPoint: TajurbaEndPoint){
        if serviceEndPoint == .sendOTP{
            AlertHelper.showOk(message: "Please enter valid credential", {
            })
        }else if serviceEndPoint == .authLoginOTP{
            AlertHelper.showAlert(message: EnumSystemAlerts.Invalid_OTP.getAlertDescription)
        }else{
            if EnumSystemAlerts.Invalid_Session.getAlertDescription == ""{
                AlertHelper.showOk(message:"Session expired, please login again", {
                    // Logout
                    self.logoutOnExpiredSession()
                })
            }else{
                AlertHelper.showOk(message: EnumSystemAlerts.Invalid_Session.getAlertDescription, {
                    // Logout
                    self.logoutOnExpiredSession()
                })
            }
        }
    }
    
    private func logoutOnExpiredSession(){
        kSharedUserDefaults.clearUserDefault()
        KAppDelegate.mainVC()
        
    }
    
    
    func uploadMedia (_ serviceEndPoint: TajurbaEndPoint, method: HTTPMethod, queries: [String: String]? = nil, parameters: Parameters? = nil, interceptor: RequestInterceptor? = nil, isShowLoading: Bool = false, requestImages arrImages: [Dictionary<String, Any>], requestVideos arrVideos: Dictionary<String, Any>, requestData postData: Dictionary<String, Any>, completion: @escaping ((Data?, Error?) -> Void)){
        
        let url = serviceEndPoint.getURL(queries: queries)
        //        let headers = serviceEndPoint.headers
        let headers: HTTPHeaders = ["Content-Type" : "multipart/form-data"]
        
        guard let url = url else {
            // Invalid url
            return
        }
        if isShowLoading{
            Utility.showLoader(message: StringConstant.PleaseWait)
        }
        
        AF.upload(
            multipartFormData: { multipartFormData in
                
                if let videoURLS = arrVideos["files"] as? [URL]{
                    for vURL in videoURLS{
                        do {
                            let videoData = try Data(contentsOf: vURL)
                            multipartFormData.append(videoData,
                                                     withName: "files",
                                                     fileName: "files.mp4",
                                                     mimeType: "video/mp4")
                        } catch {
                            print("Unable to load data: \(error)")
                        }
                    }
                }
                
                var docValue : Data
                for dictImage in arrImages
                {
                    let validDict = kSharedInstance.getDictionary(dictImage)
                    if let image = validDict[ConstantApiKeys.image] as? UIImage
                    {
                        multipartFormData.append(image.jpegData(compressionQuality: 0.5)!, withName: "files" , fileName: "files.png", mimeType: "image/png")
                    }else if let images = validDict[ConstantApiKeys.image] as? [UIImage]{
                        for image in images{
                            multipartFormData.append(image.jpegData(compressionQuality: 0.5)!, withName: "files" , fileName: "files.png", mimeType: "image/png")
                        }
                    }else if let docURLs = validDict[ConstantApiKeys.image] as? [URL]{
                        for doc in docURLs{
                            do {
                                let docData = try Data(contentsOf: doc)
                                docValue = docData
                                multipartFormData.append(docValue,
                                                         withName: "files",
                                                         fileName: "files + \(docURLs)" ,
                                                         mimeType: "application/pdf)")
                                //                                    multipartFormData.append(docValue,withName: "files",fileName: "files + \(docURLs)" ,mimeType: "application/ + \(validDict["fileFormat"])")
                                
                            }catch {
                                print("Unable to load data: \(error)")
                            }
                        }
                    }
                }
                for (key,value) in postData{
                    //Special for Create Quiz
                    if let url = value as? URL{
                        let mimeType: String
                        let fileExtension = url.pathExtension.lowercased()
                        switch fileExtension {
                        case "pdf":
                            mimeType = "application/pdf"
                        case "doc", "docx":
                            mimeType = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
                        default:
                            mimeType = "application/octet-stream"
                        }
                        
                        do {
                            if let data = try? Data(contentsOf: url){
                                multipartFormData.append(data, withName: "files", fileName: "files."+"\(url.pathExtension)", mimeType:  mimeType)
                            }
                        }
                    }
                    //                    multipartFormData.append(String.getString(value).data(using: String.Encoding.utf8, allowLossyConversion: true)!, withName: key)
                    
                    //multipartFormData.append(self.convertToData(value), withName: key)
                }
            },
            to: url, method: .post , headers: headers, interceptor: interceptor ?? self).validate()
            .responseData { (response) in
                Utility.hideLoader()
                switch response.result{
                case .success(_):
                    if let statusCode = response.response?.statusCode {
                        switch statusCode {
                            
                        case 200...299:
                            if let data = response.data {
                                do {
                                    if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                                        print(json)
                                        completion(data, nil)
                                    }
                                }catch {
                                    print(error.localizedDescription)
                                }
                                completion(data, nil)
                            }
                        case badRequest:
                            // Bad Request: Handle the specific error case
                            print("Bad Request")
                        case InvalidAccessTokenCode:
                            // Unauthorized: Handle the specific error case
                            self.handle401StatusCode(serviceEndPoint)
                            print("INVALID AUTHTOKEN") //when AuthToken is expire
                            
                        default:
                            print("Status Code: \(statusCode)")
                            break
                        }
                    }
                case .failure(let error):
                    if let statusCode = response.response?.statusCode {
                        switch statusCode {
                        case InvalidAccessTokenCode:
                            self.handle401StatusCode(serviceEndPoint)
                        default:
                            AlertHelper.showAlert(message: error.localizedDescription)
                            completion(nil, nil)
                            break
                        }
                    }
                }
            }
        
    }
    
    func uploadMedia (_ serviceEndPoint: TajurbaEndPoint, method: HTTPMethod, queries: [String: String]? = nil, parameters: Parameters? = nil, interceptor: RequestInterceptor? = nil, isShowLoading: Bool = false, mediaPaths: [[String: Any]], completion: @escaping ((Data?, Error?) -> Void)){
        
        let url = serviceEndPoint.getURL(queries: queries)
        let headers: HTTPHeaders = ["Content-Type" : "multipart/form-data"]
        
        guard let url = url else {
            // Invalid url
            return
        }
        if isShowLoading{
            Utility.showLoader(message: StringConstant.PleaseWait)
        }
        
        AF.upload(
            multipartFormData: { multipartFormData in
                for mediaPath in mediaPaths {
                    for (key,value) in mediaPath{
                        if let url = value as? URL{
                            let mimeType: String
                            var pathExtension: String = url.pathExtension
                            let fileExtension = url.pathExtension.lowercased()
                            switch fileExtension {
                            case "jpg", "jpeg":
                                mimeType = "image/jpeg"
                            case "png":
                                mimeType = "image/png"
                            case "mp4", "mov":
                                mimeType = "video/mp4"
                                pathExtension = "mp4"
                            case "pdf":
                                mimeType = "application/pdf"
                            case "doc", "docx":
                                mimeType = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
                            case "txt":
                                mimeType = "text/plain"
                            default:
                                mimeType = "application/octet-stream"
                            }
                            
                            do {
                                if let data = try? Data(contentsOf: url){
                                    multipartFormData.append(data, withName: "files", fileName: "files."+pathExtension, mimeType:  mimeType)
                                }
                            }
                        }else if let image = value as? UIImage{
                            multipartFormData.append(image.jpegData(compressionQuality: 0.5)!, withName: "files" , fileName: "files.png", mimeType: "image/png")
                        }
                    }
                }
            },
            to: url, method: .post , headers: headers, interceptor: interceptor ?? self).validate()
            .responseData { (response) in
                Utility.hideLoader()
                switch response.result{
                case .success(_):
                    if let statusCode = response.response?.statusCode {
                        switch statusCode {
                            
                        case 200...299:
                            if let data = response.data {
                                do {
                                    if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                                        print(json)
                                        completion(data, nil)
                                    }
                                }catch {
                                    print(error.localizedDescription)
                                }
                                completion(data, nil)
                            }
                        case badRequest:
                            // Bad Request: Handle the specific error case
                            print("Bad Request")
                        case InvalidAccessTokenCode:
                            // Unauthorized: Handle the specific error case
                            self.handle401StatusCode(serviceEndPoint)
                            print("INVALID AUTHTOKEN") //when AuthToken is expire
                            
                        default:
                            print("Status Code: \(statusCode)")
                            break
                        }
                    }
                case .failure(let error):
                    if let statusCode = response.response?.statusCode {
                        switch statusCode {
                        case InvalidAccessTokenCode:
                            self.handle401StatusCode(serviceEndPoint)
                        default:
                            AlertHelper.showAlert(message: error.localizedDescription)
                            completion(nil, nil)
                            break
                        }
                    }
                }
            }
    }
}


extension NetworkManager: RequestInterceptor {
    
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var request = urlRequest
        guard let token = kSharedUserDefaults.getAccessToken() else {
            completion(.success(urlRequest))
            return
        }
        
        let bearerToken = "Bearer \(token)"
        request.setValue(bearerToken, forHTTPHeaderField: StringConstant.authorization)
        completion(.success(request))
    }
    
    func retry(_ request: Request, for session: Session, dueTo error: Error,
               completion: @escaping (RetryResult) -> Void) {
        guard let statusCode = request.response?.statusCode, statusCode == 401 else {
            completion(.doNotRetry)
            return
        }
        print("⚠️⚠️⚠️⚠️retry statusCode....\(statusCode)⚠️⚠️⚠️⚠️")
        
        guard request.retryCount < retryLimit else {
            completion(.doNotRetry)
            return
        }
        self.refreshToken(.refreshAccessToken) { success in
            success ? completion(.retry) : completion(.doNotRetry)
        }
    }
    
    func refreshToken(_ serviceEndPoint: TajurbaEndPoint, completion: @escaping (_ isSuccess: Bool) -> Void) {
        guard let refreshToken = kSharedUserDefaults.getRefreshToken() else {
            completion(false)
            return
        }
        let url = serviceEndPoint.getURL(queries: nil)
        let params = ["refreshToken": refreshToken]
        
        guard let url = url else {
            print("Invalid URL--->", url?.absoluteString ?? "Refresh URL is invalid")
            completion(false)
            return
        }
        AF.request(url, method: .post, parameters: params, encoding: JSONEncoding.default).responseData { response in
            switch response.response?.statusCode{
            case 200:
                if let data = response.data{
                    do {
                        let result = try JSONDecoder().decode(RefreshAccessTokenModel.self, from: data)
                        
                        // FIXME: - Comment before release
                        if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                            if let apiData = json["data"] as? [String: Any]{
                                print("✅✅✅✅",result)
                            }
                        }
                        
                        kSharedUserDefaults.setAccessToken(accessToken: result.data?.access_token ?? "" )
                        kSharedUserDefaults.setRefreshToken(refreshToken: result.data?.refresh_token ?? "")
                        completion(true)
                    }catch{
                        print("Error")
                        completion(false)
                    }
                }
                
            default:
                print("refresh token expire--->logout")
                completion(false)
                
            }
            
        }
    }
}

extension Data{
    func getResponseDataDictionaryFromData(data: Data) -> (responseData: Dictionary<String, Any>?, error: Error?){
        do{
            let responseData = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? Dictionary<String, Any>
            return (responseData, nil)
        }
        catch let error{
            debugPrint( "json error: \(error.localizedDescription)")
            return (nil, error)
        }
    }
}
