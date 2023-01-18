//
//  DeviceAddingZigbeeSubdeviceTableViewController.swift
//  smart-life-sdk
//
//  Created by Sittipong Suwannatrai on 18/1/23.
//

import UIKit
import SVProgressHUD
import TuyaSmartActivatorKit

class DeviceAddingZigbeeSubdeviceTableViewController: UITableViewController {

    typealias DeviceAddingSuccessCallback = () -> Void

    @IBOutlet weak var gatewayNameLabel: UILabel!
    
    private var gateway: TuyaSmartDeviceModel?
    private var onSuccess: DeviceAddingSuccessCallback?
    
    private var tuyaPairingToken: String?
    private var tuyaActivator: TuyaSmartActivator? { return TuyaSmartActivator.sharedInstance() }
    
    private var isSuccess = false
    
    func configure(
        gateway: TuyaSmartDeviceModel?,
        onSuccess: DeviceAddingSuccessCallback?
    ) {
        self.gateway = gateway
        self.onSuccess = onSuccess
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        gatewayNameLabel.text = gateway?.name ?? "-"
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
        
        let logoutIndexPath = IndexPath(row: 1, section: 1)
        if (indexPath == logoutIndexPath) {
            searchTapped(tableView)
        }
    }

}

private extension DeviceAddingZigbeeSubdeviceTableViewController {
    
    func startDevicePairing() {
        guard let gatewayDeviceId = gateway?.devId else {
            SVProgressHUD.showError(
                withStatus: "Tuya pairing data isn't ready."
            )
            return
        }
        
        SVProgressHUD.show(withStatus: "Configuring")
        tuyaActivator?.delegate = self
        tuyaActivator?.activeSubDevice(
            withGwId: gatewayDeviceId,
            timeout: 100
        )
    }
    
    func stopDevicePairing() {
        if !isSuccess {
            SVProgressHUD.dismiss()
        }
        
        tuyaActivator?.delegate = nil
        
        if let gatewayDeviceId = gateway?.devId {
            tuyaActivator?.stopActiveSubDevice(withGwId: gatewayDeviceId)
        }
    }
    
}

extension DeviceAddingZigbeeSubdeviceTableViewController: TuyaSmartActivatorDelegate {
    
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
    
}
