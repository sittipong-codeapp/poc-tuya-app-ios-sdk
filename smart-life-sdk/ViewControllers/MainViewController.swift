//
//  HomeViewController.swift
//  smart-life-sdk
//
//  Created by Sittipong Suwannatrai on 13/1/23.
//

import UIKit
import TuyaSmartBaseKit
import TuyaSmartDeviceKit

class MainViewController: UITableViewController {
    
    private var listViewSections: [ListViewSection] = []
    
    private let user = TuyaSmartUser.sharedInstance()
    private var userName: String { return user.userName.split(separator: "@").first?.capitalized ?? "Anonymous" }
    
    private var currentHome: TuyaSmartHome?
    private var currentHomeModel: TuyaSmartHomeModel?
    private var currentHomeName: String { return currentHomeModel?.name ?? "-" }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        setupData()
    }
    
    // MARK: - Actions
    
    @IBAction func addDeviceTapped(_ sender: Any) {
        let options = [
            ("Wi-Fi, AP Mode", "DeviceAddingAPMode"),
            ("Zigbee Gateway", "DeviceAddingZigbeeGateway"),
            ("Zigbee Subdevice", "DeviceAddingZigbeeSubdevice")
        ]
        let actions = options.map { (title, segueId) in
            return UIAlertAction(
                title: title,
                style: .default,
                handler: { [weak self] action in
                    self?.performSegue(withIdentifier: segueId, sender: self)
                }
            )
        }
        
        Alert.showActionSheet(
            on: self,
            with: "Device Adding Options",
            message: nil,
            actions: actions
        )
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return listViewSections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listViewSections[section].items.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return listViewSections[section].title
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let data = listViewSections[indexPath.section].items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: data.identifier, for: indexPath)

        return configureCell(cell, data: data)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    private func configureCell(_ cell: UITableViewCell, data: ListViewCell) -> UITableViewCell {
        if let data = data as? GreetingCell {
            cell.textLabel?.text = data.message
        } else if let data = data as? InformationCell {
            cell.textLabel?.text = data.title
            cell.detailTextLabel?.text = data.detail
        } else if let data = data as? InformationWithDisclosureCell {
            cell.textLabel?.text = data.title
            cell.detailTextLabel?.text = data.detail
        } else if let cell = cell as? DeviceTableViewCell, let data = data as? DeviceCell {
            cell.titleLabel.text = data.deviceName
            cell.connectivityStatusLabel.text = data.device.map({ $0.deviceModel.isOnline ? "Online" : "Offline" }) ?? "Unknown"
            cell.statusSwitch.isOn = data.isOn ?? false
            cell.statusSwitch.isHidden = data.isOn == nil
            cell.statusSwitch.isEnabled = data.device != nil
            cell.switchAction = { [weak self] switchButton in
                guard let self = self,
                      let dpID = data.powerSwitchDpId
                else { return }
                
                self.publishMessage(
                    with: [dpID : switchButton.isOn],
                    device: data.device!
                )
            }
        }
        
        return cell
    }
    
    private func publishMessage(with dps: NSDictionary, device: TuyaSmartDevice) {
        guard let dps = dps as? [AnyHashable : Any] else { return }

        device.publishDps(dps, success: {
        }, failure: { (error) in
            let errorMessage = error?.localizedDescription ?? ""
            SVProgressHUD.showError(withStatus: errorMessage)
        })
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deviceListSectionIndex = 2
        
        switch indexPath.section {
        case deviceListSectionIndex:
            return UISwipeActionsConfiguration(
                actions: [
                    UIContextualAction(
                        style: .destructive,
                        title: "Remove",
                        handler: { [weak self] action, sourceView, completionHandler in
                            guard self != nil, let deviceCell = self?.listViewSections[indexPath.section].items[indexPath.row] as? DeviceCell,
                                  let device = deviceCell.device else {return completionHandler(false)}
                            
                            SVProgressHUD.show(withStatus: "Device Removing")
                            device.remove({ [weak self] in
                                guard let self = self else { return }
                                
                                
                                let name = deviceCell.deviceName
                                SVProgressHUD.showSuccess(withStatus: "Successfully Removed\n\(name)")
                                self.updateData()
                                completionHandler(true)
                            }, failure: { [weak self] error in
                                guard let self = self else { return }
                                
                                let errorMessage = error?.localizedDescription ?? ""
                                Alert.showBasicAlert(on: self, with: NSLocalizedString("Failed to Remove", comment: "Failed to remove the device"), message: errorMessage)
                                completionHandler(false)
                            })
                        }
                    ),
                ]
            )
        default:
            return nil
        }
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? DeviceAddingAPModeTableViewController {
            vc.configure(onSuccess: updateData)
        } else if let vc = segue.destination as? DeviceAddingZigbeeGatewayTableViewController {
            vc.configure(onSuccess: updateData)
        } else if let vc = segue.destination as? DeviceAddingZigbeeSubdeviceTableViewController {
            let gateway = currentHome?.deviceList.first(where: { $0.deviceType == TuyaSmartDeviceModelTypeZigbeeGateway })
            vc.configure(
                gateway: gateway,
                onSuccess: updateData
            )
        }
    }

}

private extension MainViewController {
    
    func setupView() {
        tableView.estimatedRowHeight = 55
        tableView.rowHeight = UITableView.automaticDimension
    }
    
    func setupData() {
        initiateCurrentHome()
    }
    
    func initiateCurrentHome() {
        let homeManager = TuyaSmartHomeManager()
        
        homeManager.getHomeList { [weak self] homes in
            guard let self = self,
            let currentHomeModel = homes?.first
            else { return }
            
            self.setCurrentHomeModel(currentHomeModel)
            self.updateHomeDetail()
        } failure: { [weak self] error in
            guard let self = self else { return }
            
            let errorMessage = error?.localizedDescription ?? ""
            Alert.showBasicAlert(
                on: self,
                with: "Failed to get home list.",
                message: errorMessage
            )
        }
    }
    
    func updateData() {
        let home: TuyaSmartHome? = currentHome
        
        let devices: [ListViewCell] = home?.deviceList?.map({ device in
            let switchSchema = device.schemaArray?.first(where: { schema in
                let type = schema.type == "obj" ? schema.property.type : schema.type
                return type == "bool" && schema.mode != "ro" && schema.iconname.contains("power")
            })
            let switchDpId = switchSchema?.dpId
            let isOn = switchDpId.flatMap({ id in device.dps[id] as? Bool })
            
            return DeviceCell(
                deviceName: device.name,
                isOn: isOn,
                device: TuyaSmartDevice(deviceId: device.devId),
                powerSwitchDpId: switchDpId
            )
        }) ?? []
        
        listViewSections = [
            ListViewSection(
                title: nil,
                items: [
                    GreetingCell(userName: userName),
                    InformationCell(title: "User ID", detail: user.uid),
                    InformationCell(title: "Session ID", detail: user.sid),
                ]
            ),
            ListViewSection(
                title: "Home Management",
                items: [
                    InformationWithDisclosureCell(
                        title: "Current Home",
                        detail: currentHomeName
                    )
                ]
            ),
            ListViewSection(
                title: "Device List",
                items: devices
            )
        ]
        
        tableView.reloadData()
    }
    
    func updateHomeDetail() {
        guard let home = currentHome else { return }
        
        home.getDataWithSuccess({ [weak self] (model) in
            guard let self = self,
                  let model = model
            else { return }
            
            self.setCurrentHomeModel(model)
        }, failure: { [weak self] (error) in
            guard let self = self else { return }
            let errorMessage = error?.localizedDescription ?? ""
            Alert.showBasicAlert(
                on: self,
                with: "Failed to Fetch Home",
                message: errorMessage
            )
        })
        
        home.syncHomeDeviceList { [weak self] in
            self?.updateData()
        } failure: { [weak self] error in
            guard let self = self else { return }
            let errorMessage = error?.localizedDescription ?? ""
            Alert.showBasicAlert(
                on: self,
                with: "Failed to Fetch Home",
                message: errorMessage
            )
        }
    }
    
    func setCurrentHomeModel(_ model: TuyaSmartHomeModel) {
        currentHomeModel = model
        TuyaHome.current = model
        currentHome = TuyaSmartHome(homeId: model.homeId)
        currentHome?.delegate = self
        
        updateData()
    }
    
}

extension MainViewController: TuyaSmartHomeDelegate{

    func homeDidUpdateInfo(_ home: TuyaSmartHome!) {
        updateData()
    }
    
    func home(_ home: TuyaSmartHome!, didAddDeivice device: TuyaSmartDeviceModel!) {
        updateData()
    }
    
    func home(_ home: TuyaSmartHome!, didRemoveDeivice devId: String!) {
        updateData()
    }
    
    func home(_ home: TuyaSmartHome!, deviceInfoUpdate device: TuyaSmartDeviceModel!) {
        updateData()
    }
    
    func home(_ home: TuyaSmartHome!, device: TuyaSmartDeviceModel!, dpsUpdate dps: [AnyHashable : Any]!) {
        updateData()
    }

}

class DeviceTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var connectivityStatusLabel: UILabel!
    @IBOutlet weak var statusSwitch: UISwitch!
    
    var switchAction: ((UISwitch) -> Void)?
    
    @IBAction func switchTapped(_ sender: UISwitch) {
        switchAction?(sender)
    }
}

// MARK: - Cell

struct GreetingCell: ListViewCell {
    let identifier = "GreetingCell"
    let userName: String
    
    var message: String { return "Hello, \(userName)!" }
}

struct InformationCell: ListViewCell {
    let identifier = "InformationCell"
    let title: String
    let detail: String
}

struct InformationWithDisclosureCell: ListViewCell {
    let identifier = "InformationWithDisclosureCell"
    let title: String
    let detail: String
}

struct DeviceCell: ListViewCell {
    let identifier = "DeviceCell"
    let deviceName: String
    var isOn: Bool?
    let device: TuyaSmartDevice?
    let powerSwitchDpId: String?
}

// MARK: - Helper

protocol ListViewChild {}

protocol ListViewCell: ListViewChild {
    var identifier: String { get }
}

struct ListViewSection: ListViewChild {
    let title: String?
    let items: [ListViewCell]
}
