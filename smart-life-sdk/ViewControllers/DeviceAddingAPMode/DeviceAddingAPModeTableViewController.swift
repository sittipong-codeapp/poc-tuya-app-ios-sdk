//
//  DeviceAddingAPModeTableViewController.swift
//  smart-life-sdk
//
//  Created by Sittipong Suwannatrai on 17/1/23.
//

import UIKit
import SVProgressHUD
import TuyaSmartActivatorKit

class DeviceAddingAPModeTableViewController: UITableViewController {
    
    typealias DeviceAddingSuccessCallback = () -> Void

    @IBOutlet weak var ssidTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var tuyaPairingTokenLabel: UILabel!
    
    private var onSuccess: DeviceAddingSuccessCallback?

    private var tuyaPairingToken: String?
    private var ssid: String? { return ssidTextField.text }
    private var password: String? { return passwordTextField.text }
    private var tuyaActivator: TuyaSmartActivator? { return TuyaSmartActivator.sharedInstance() }
    
    private var isSuccess = false
    
    func configure(onSuccess: DeviceAddingSuccessCallback?) {
        self.onSuccess = onSuccess
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        stopDevicePairing()
    }
    
    // MARK: - Actions
    
    @IBAction func searchTapped(_ sender: Any) {
        startDevicePairing()
    }
    
    // MARK: - TableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let logoutIndexPath = IndexPath(row: 1, section: 2)
        if (indexPath == logoutIndexPath) {
            searchTapped(tableView)
        }
    }
    
}

private extension DeviceAddingAPModeTableViewController {
    
    func setupData() {
        fetchTuyaPairingToken()
    }
    
    func updateData() {
        tuyaPairingTokenLabel.text = tuyaPairingToken
    }
    
    func fetchTuyaPairingToken() {
        guard let homeId = TuyaHome.current?.homeId else { return }
        
        tuyaActivator?.getTokenWithHomeId(
            homeId,
            success: { [weak self] (token) in
                guard let self = self else { return }
                
                self.tuyaPairingToken = token
                self.updateData()
            },
            failure: { (error) in
                let errorMessage = error?.localizedDescription ?? ""
                SVProgressHUD.showError(withStatus: errorMessage)
            }
        )
    }
    
    func startDevicePairing() {
        let ssid: String = self.ssid ?? ""
        let password: String = self.password ?? ""
        let token: String = tuyaPairingToken ?? ""
        
        SVProgressHUD.show(withStatus: "Configuring")
        tuyaActivator?.delegate = self
        tuyaActivator?.startConfigWiFi(
            .AP,
            ssid: ssid,
            password: password,
            token: token,
            timeout: 100
        )
    }
    
    func stopDevicePairing() {
        if !isSuccess {
            SVProgressHUD.dismiss()
        }
        
        tuyaActivator?.delegate = nil
        tuyaActivator?.stopConfigWiFi()
    }
    
}

extension DeviceAddingAPModeTableViewController: TuyaSmartActivatorDelegate {
    
    func activator(_ activator: TuyaSmartActivator!, didReceiveDevice deviceModel: TuyaSmartDeviceModel!, error: Error!) {
        if deviceModel != nil && error == nil {
            // Success
            let name = deviceModel.name ?? "Unknown name device."
            SVProgressHUD.showSuccess(withStatus: "Successfully Added\n\(name)")
            isSuccess = true
            onSuccess?()
            navigationController?.popViewController(animated: true)
        }
        
        if let error = error {
            // Error
            SVProgressHUD.showError(withStatus: error.localizedDescription)
        }
    }
    
    func activator(_ activator: TuyaSmartActivator!, didPassWIFIToSecurityLevelDeviceWithUUID uuid: String!) {
        SVProgressHUD.dismiss()
        Alert.showBasicAlert(on: self, with: "SecurityLevelDevice", message: "continue pair? (Please check you phone connected the same Wi-Fi as you Inputed)", actions: [
            UIAlertAction(title: "cancel", style: .cancel),
            UIAlertAction(title: "continue", style: .destructive, handler: { _ in
                TuyaSmartActivator.sharedInstance().continueConfigSecurityLevelDevice()
                SVProgressHUD.show(withStatus: NSLocalizedString("Configuring", comment: ""))
            })
        ])
    }
    
}
