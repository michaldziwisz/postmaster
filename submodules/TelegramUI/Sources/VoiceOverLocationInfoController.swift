import UIKit
import MapKit
import TelegramCore
import TelegramPresentationData
import TelegramStringFormatting
import AccountContext

private struct VoiceOverLocationSection {
    let header: String?
    let rows: [VoiceOverLocationRow]
}

private struct VoiceOverLocationRow {
    let title: String
    let subtitle: String?
    let iconSystemName: String?
    let action: (() -> Void)?
}

final class VoiceOverLocationInfoController: UITableViewController, UIAdaptivePresentationControllerDelegate {
    private let context: AccountContext
    private let presentationData: PresentationData
    private let location: TelegramMediaMap
    private let onDismiss: (() -> Void)?
    
    private var sections: [VoiceOverLocationSection] = []
    
    init(context: AccountContext, presentationData: PresentationData, location: TelegramMediaMap, onDismiss: (() -> Void)? = nil) {
        self.context = context
        self.presentationData = presentationData
        self.location = location
        self.onDismiss = onDismiss
        
        super.init(style: .insetGrouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = self.displayTitle
        self.navigationItem.largeTitleDisplayMode = .never
        self.view.backgroundColor = .systemBackground
        self.view.accessibilityViewIsModal = UIAccessibility.isVoiceOverRunning
        self.presentationController?.delegate = self
        
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 60.0
        self.tableView.cellLayoutMarginsFollowReadableWidth = true
        
        let backButtonItem = UIBarButtonItem(title: self.presentationData.strings.Common_Back, style: .plain, target: self, action: #selector(self.backPressed))
        backButtonItem.accessibilityLabel = self.presentationData.strings.Common_Back
        self.navigationItem.leftBarButtonItem = backButtonItem
        
        self.reloadSections()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.presentationController?.delegate = self
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sections[section].rows.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sections[section].header
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "VoiceOverLocationInfoCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell(style: .subtitle, reuseIdentifier: identifier)
        let row = self.sections[indexPath.section].rows[indexPath.row]
        
        cell.textLabel?.text = row.title
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.text = row.subtitle
        cell.detailTextLabel?.numberOfLines = 0
        if let iconSystemName = row.iconSystemName {
            cell.imageView?.image = UIImage(systemName: iconSystemName)
            cell.imageView?.tintColor = self.view.tintColor
        } else {
            cell.imageView?.image = nil
        }
        
        cell.accessoryType = row.action != nil ? .disclosureIndicator : .none
        cell.selectionStyle = row.action != nil ? .default : .none
        cell.isAccessibilityElement = true
        if let subtitle = row.subtitle, !subtitle.isEmpty {
            cell.accessibilityLabel = "\(row.title), \(subtitle)"
        } else {
            cell.accessibilityLabel = row.title
        }
        cell.accessibilityTraits = row.action != nil ? [.button] : [.staticText]
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.sections[indexPath.section].rows[indexPath.row].action?()
    }
    
    override func accessibilityPerformEscape() -> Bool {
        self.backPressed()
        return true
    }
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.onDismiss?()
    }
    
    @objc private func backPressed() {
        let onDismiss = self.onDismiss
        self.dismiss(animated: true, completion: onDismiss)
    }
    
    private var displayTitle: String {
        if let venue = self.location.venue, !venue.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return venue.title
        } else if self.location.liveBroadcastingTimeout != nil {
            return self.presentationData.strings.Map_SharingLocation
        } else {
            return self.presentationData.strings.Map_LocationTitle
        }
    }
    
    private func reloadSections() {
        var sections: [VoiceOverLocationSection] = []
        
        let detailsSubtitle = self.addressText ?? self.coordinateText
        let actionRows: [VoiceOverLocationRow] = [
            VoiceOverLocationRow(
                title: self.presentationData.strings.Map_OpenIn,
                subtitle: "Maps",
                iconSystemName: "map.fill",
                action: { [weak self] in
                    self?.openInMaps()
                }
            ),
            VoiceOverLocationRow(
                title: self.presentationData.strings.Map_GetDirections,
                subtitle: detailsSubtitle,
                iconSystemName: "car.fill",
                action: { [weak self] in
                    self?.openDirections()
                }
            )
        ]
        sections.append(VoiceOverLocationSection(header: nil, rows: actionRows))
        
        var detailRows: [VoiceOverLocationRow] = []
        if let venue = self.location.venue, !venue.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            detailRows.append(VoiceOverLocationRow(title: self.presentationData.strings.Map_Location, subtitle: venue.title, iconSystemName: nil, action: nil))
        }
        if let addressText = self.addressText {
            detailRows.append(VoiceOverLocationRow(title: "Address", subtitle: addressText, iconSystemName: nil, action: nil))
        }
        detailRows.append(VoiceOverLocationRow(title: "Coordinates", subtitle: self.coordinateText, iconSystemName: nil, action: nil))
        if let accuracyText = self.accuracyText {
            detailRows.append(VoiceOverLocationRow(title: "Accuracy", subtitle: accuracyText, iconSystemName: nil, action: nil))
        }
        if let heading = self.location.heading {
            detailRows.append(VoiceOverLocationRow(title: "Heading", subtitle: "\(heading)°", iconSystemName: nil, action: nil))
        }
        if self.location.liveBroadcastingTimeout != nil {
            detailRows.append(VoiceOverLocationRow(title: self.presentationData.strings.Map_SharingLocation, subtitle: nil, iconSystemName: nil, action: nil))
        }
        sections.append(VoiceOverLocationSection(header: nil, rows: detailRows))
        
        self.sections = sections
        self.tableView.reloadData()
    }
    
    private var addressText: String? {
        if let venueAddress = self.location.venue?.address?.trimmingCharacters(in: .whitespacesAndNewlines), !venueAddress.isEmpty {
            return venueAddress
        }
        
        guard let address = self.location.address else {
            return nil
        }
        
        let components = [
            address.street,
            address.city,
            address.state,
            address.country
        ]
        .compactMap { value -> String? in
            guard let value else {
                return nil
            }
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        
        if components.isEmpty {
            return nil
        } else {
            return components.joined(separator: "\n")
        }
    }
    
    private var coordinateText: String {
        return String(format: "%.6f, %.6f", self.location.latitude, self.location.longitude)
    }
    
    private var accuracyText: String? {
        guard let accuracyRadius = self.location.accuracyRadius else {
            return nil
        }
        return self.presentationData.strings.Map_AccurateTo(stringForDistance(strings: self.presentationData.strings, distance: accuracyRadius)).string
    }
    
    private func openInMaps() {
        let mapItem = self.mapItem()
        if !mapItem.openInMaps(launchOptions: nil) {
            self.presentUnavailableAlert()
        }
    }
    
    private func openDirections() {
        let mapItem = self.mapItem()
        let didOpen = MKMapItem.openMaps(
            with: [MKMapItem.forCurrentLocation(), mapItem],
            launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        )
        if !didOpen {
            self.presentUnavailableAlert()
        }
    }
    
    private func mapItem() -> MKMapItem {
        let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: self.location.latitude, longitude: self.location.longitude))
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = self.displayTitle
        return mapItem
    }
    
    private func presentUnavailableAlert() {
        let controller = UIAlertController(title: nil, message: self.presentationData.strings.Login_UnknownError, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: self.presentationData.strings.Common_OK, style: .default))
        self.present(controller, animated: true)
    }
}
