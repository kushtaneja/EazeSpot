//
//  TeamSelectionViewController.swift
//  Eazespot
//
//  Created by Kush Taneja on 02/12/16.
//  Copyright © 2016 Kush Taneja. All rights reserved.
//

import UIKit
import SWXMLHash
import XMPPFramework


class TeamSelectionViewController: UIViewController,UIPickerViewDelegate,UIPickerViewDataSource{
    
    @IBOutlet weak var companyListPickerViewController: UIPickerView!
    var companysArray = [Company]()
    var selectedTeamId = Int()
    var userChatId = String()
    var userChatPassword = String()
    var loginPassword = String()
    var loginUsername = String()
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        selectedTeamId = companysArray[0].company_id
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return companysArray.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?{
        return  "\(companysArray[row].company_name)"
        
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedTeamId = companysArray[row].company_id
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let string = "\(companysArray[row].company_name)"
        let attributedString = NSAttributedString(string: string, attributes: [NSForegroundColorAttributeName:ColorCode().appThemeColor])
        return attributedString
        
        
    }
    
    @IBAction func DoneButtonTapped(_ sender: UIBarButtonItem) {
        loginCall(email: loginUsername, password: loginPassword, company_id: selectedTeamId)
        
    }
    
    
    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    
    
    func loginCall(email:String, password: String, company_id: Int){
        let params: [String:Any] = ["username": email ,"password": password , "company": company_id]
        
        LoginService().loginCall(self.view, params: params, onSuccess: {(data: JSON) in
            
            let user_id = data["user_id"].stringValue
            
            if (UserDefaults.standard.value(forKey: "user_id") !=  nil)
            {
                if ((UserDefaults.standard.value(forKey: "user_id") as! String) == user_id ) {
                }
                else {
                    EazeChat.sharedInstance.disconnect()
//                   EazeMessage.sharedInstance.deleteMessages()
                    EazeRoster.removeUsers()
                    
                    self.setValue(value: user_id, forKey: "user_id")
                   
                }
                
            }
            else {
                self.setValue(value: user_id, forKey: "user_id")
            }
            let jwt_token = data["key"].stringValue
            let company_name = data["company_name"].stringValue
            
            self.setValue(value: jwt_token, forKey: "JWT_key")
            
            self.userChatId = (data["cid"].stringValue).fromBase64()
            self.userChatPassword = (data["cip"].stringValue).fromBase64()
            self.setValue(value: self.userChatId + "@chat.eazespot.com", forKey: kXMPP.myJID)
            self.setValue(value: self.userChatPassword, forKey: kXMPP.myPassword)
            
            EazeChat.sharedInstance.connect()
            
            let params = ["company_id": String(self.selectedTeamId), "user_id": user_id] as [String : Any]
            
            ProfileService().profileCall(self.view, params: params, onSuccess: {(profdata: JSON) in
                
                let firstname = profdata["user"]["first_name"].stringValue
                let lastname = profdata["user"]["last_name"].stringValue
                let email = profdata["user"]["email"].stringValue
                let profilePicUrl =  profdata["profile_pic"]["L"].stringValue
                print("**ID:: \(profdata["id"])***FirstName::: \(firstname)")
                let user = LoggedinUserProfile(userFirstName: firstname, userLastName: lastname, userEmail: email,userPicUrl: profilePicUrl,companyName: company_name)
                let ProfDisplayNavigationScreen = UIStoryboard.ProfDisplayNavigationScreen()
                let ProfDisplayScreen = ProfDisplayNavigationScreen.topViewController as! UserProfileDisplayViewController
                ProfDisplayScreen.loggedinUser = user
                
                ActivityIndicator.shared.hideProgressView()
                
                UserDefaults.standard.setValue(false, forKey: "logout")
                UIApplication.topViewController()?.present(ProfDisplayNavigationScreen, animated: true, completion: nil)
                
            }, failed: {(errorCode: Int) in debugPrint("loginError")})
            
            
        },failed: {(errorCode: Int) in debugPrint("MultipleTeamUserLoginError")})
        
    }
    
    // Mark: Private function
    
    private func setValue(value: String, forKey key: String) {
        if value.characters.count > 0 {
            UserDefaults.standard.set(value, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}
