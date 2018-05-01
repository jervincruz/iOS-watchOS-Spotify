//
//  ViewController.swift
//  Spotify
//
//  Created by Jervin Cruz on 4/30/18.
//  Copyright © 2018 Jervin Cruz. All rights reserved.
//

import UIKit
import Alamofire
import SafariServices
import AVFoundation
import SpotifyLogin

class ViewController: UIViewController, SPTAudioStreamingDelegate, SPTAudioStreamingPlaybackDelegate {
    @IBOutlet var loginButton: UIButton!
    
    var searchURL = "https://api.spotify.com/v1/search?q=Shawn%20Mendes&type=track"
    var authorizeURL = "https://accounts.spotify.com/authorize"
    let redirectURL = "spotify://callback"
    let clientID = "22b0b08ff2d946aea86fd04a09bcec58"
    var accessToken = ""
    
    typealias JSONStandard = [String : AnyObject]
    
    var auth = SPTAuth.defaultInstance()!
    var session : SPTSession!
    var player : SPTAudioStreamingController?
    var loginURL : URL?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Add a log in button
        let button = SpotifyLoginButton(viewController: self, scopes: [.streaming, .userLibraryRead])
        self.view.addSubview(button)
        
        // Retrieve the access token
        SpotifyLogin.shared.getAccessToken { (accessToken, error) in
            if error != nil {
                // User is not logged in, show log in flow.
                print("Access Token: ", accessToken!)
            } else {
                print("Access Token: ", accessToken!)
                self.accessToken = accessToken!
                NotificationCenter.default.addObserver(self, selector: #selector(self.loginSuccessful), name: .SpotifyLoginSuccessful, object: nil)
            }
        }

        
        setup()
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.updateAfterFirstLogin), name: NSNotification.Name(rawValue: "loginSuccessfull"), object: nil)
        
    }
    
    @objc func loginSuccessful(){
        let username = SpotifyLogin.shared.username
        print("Username: ", SpotifyLogin.shared.username)
        callAlamo(url: searchURL)
    }
    
    func authorizeSpotify(url: String){
        let parameters : [String : String] = ["client_id" : clientID,
                                                 "response_type" : "code",
                                                 "redirect_uri" : redirectURL]
        Alamofire.request(url, parameters: parameters).responseString    { response in
                print(response)
        }
    }
    
    func callAlamo(url: String) {
        Alamofire.request(url, method: .get, headers: ["Authorization":"Bearer " + accessToken]).responseJSON { response in
            self.parseData(JSONData: response.data!)
        }
    }
    
//    func postAlamo(url: String) {
//        Alamofire.request(.POST, "http://myserver.com", parameters: parameters, encoding: .JSON)
//            .responseJSON { request, response, JSON, error in
//                print(response)
//                print(JSON)
//                print(error)
//        }
//    }
    
    func parseData(JSONData : Data) {
        do {
            var readableJSON = try JSONSerialization.jsonObject(with: JSONData, options: .mutableContainers) as? JSONStandard
            print(readableJSON)
        }
        catch {
            print(error)
        }
    }
    
    @objc func updateAfterFirstLogin() {
        
        let userDefaults = UserDefaults.standard
        
        if let sessionObj : AnyObject = userDefaults.object(forKey: "SpotifySession") as AnyObject? {
            let sessionDataObj = sessionObj as! Data
            
            let firstTimeSession = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) as! SPTSession
            
            self.session = firstTimeSession
            
            initializePlayer(authSession: session)
        }
    }
    
    func initializePlayer(authSession : SPTSession) {
        if self.player == nil {
            self.player = SPTAudioStreamingController.sharedInstance()
            self.player!.playbackDelegate = self
            self.player!.delegate = self
            try! player!.start(withClientId: self.auth.clientID)
            self.player!.login(withAccessToken: authSession.accessToken)
        }
    }
    
    func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController!) {
        // after a user authenticates a session, the SPTAudioStreamingController is then initialized and this method called
        print("logged in")
        self.player?.playSpotifyURI("spotify:track:58s6EuEYJdlb0kO7awm3Vp", startingWith: 0, startingWithPosition: 0, callback: { (error) in
            if (error != nil) {
                print("playing!")
            }
        })
        DispatchQueue.main.async {
            self.authorizeSpotify(url: self.authorizeURL)

            self.callAlamo(url: self.searchURL)
        }
    }
    
    func setup() {
        auth.redirectURL = URL(string: redirectURL)
        auth.clientID = "22b0b08ff2d946aea86fd04a09bcec58"
        auth.requestedScopes = [SPTAuthStreamingScope, SPTAuthPlaylistReadPrivateScope, SPTAuthPlaylistModifyPublicScope, SPTAuthPlaylistModifyPrivateScope]
        loginURL = auth.spotifyWebAuthenticationURL()
        print("Hello World")
    }
    
    @IBAction func loginBtnPressed(_ sender: Any) {
        
        if UIApplication.shared.openURL(loginURL!) {
            if (auth.canHandle(auth.redirectURL)) {
                // To do -- build in error handling
            }
        }
        
    }
    

}

