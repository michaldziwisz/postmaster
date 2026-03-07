import UIKit
import Contacts
import ContactsUI
import TelegramCore
import AccountContext
import TelegramPresentationData

private struct VoiceOverContactSection {
    let rows: [VoiceOverContactRow]
}

private struct VoiceOverContactRow {
    let title: String
    let subtitle: String?
    let iconSystemName: String?
    let action: (() -> Void)?
}

final class VoiceOverContactInfoController: UITableViewController, CNContactViewControllerDelegate, UIAdaptivePresentationControllerDelegate {
    private let context: AccountContext
    private let presentationData: PresentationData
    private let contactData: DeviceContactExtendedData
    private let peer: EnginePeer?
    private let onDismiss: (() -> Void)?
    
    private var sections: [VoiceOverContactSection] = []
    private var temporaryUrls: [URL] = []
    
    init(context: AccountContext, presentationData: PresentationData, contactData: DeviceContactExtendedData, peer: EnginePeer?, onDismiss: (() -> Void)? = nil) {
        self.context = context
        self.presentationData = presentationData
        self.contactData = contactData
        self.peer = peer
        self.onDismiss = onDismiss
        
        super.init(style: .insetGrouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        for url in self.temporaryUrls {
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = self.contactDisplayTitle
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
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "VoiceOverContactInfoCell"
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
    
    func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
        viewController.dismiss(animated: true)
    }
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.onDismiss?()
    }
    
    @objc private func backPressed() {
        let onDismiss = self.onDismiss
        self.dismiss(animated: true, completion: onDismiss)
    }
    
    private var contactDisplayTitle: String {
        let parts = [
            self.contactData.prefix,
            self.contactData.basicData.firstName,
            self.contactData.middleName,
            self.contactData.basicData.lastName,
            self.contactData.suffix
        ].filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        if !parts.isEmpty {
            return parts.joined(separator: " ")
        }
        if !self.contactData.organization.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return self.contactData.organization
        }
        return self.presentationData.strings.Conversation_Contact
    }
    
    private func reloadSections() {
        var sections: [VoiceOverContactSection] = []
        
        let primaryPhone = self.contactData.basicData.phoneNumbers.first?.value.trimmingCharacters(in: .whitespacesAndNewlines)
        let primaryEmail = self.contactData.emailAddresses.first?.value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var actionRows: [VoiceOverContactRow] = []
        if let phone = primaryPhone, !phone.isEmpty {
            actionRows.append(VoiceOverContactRow(title: "Call", subtitle: phone, iconSystemName: "phone.fill", action: { [weak self] in
                self?.openUrlString("tel://\(phone)")
            }))
            actionRows.append(VoiceOverContactRow(title: "Message", subtitle: phone, iconSystemName: "message.fill", action: { [weak self] in
                self?.openUrlString("sms:\(phone)")
            }))
            actionRows.append(VoiceOverContactRow(title: "Video", subtitle: phone, iconSystemName: "video.fill", action: { [weak self] in
                self?.openUrlString("facetime://\(phone)")
            }))
            actionRows.append(VoiceOverContactRow(title: "Add to Contacts", subtitle: nil, iconSystemName: "person.crop.circle.badge.plus", action: { [weak self] in
                self?.presentAddToContacts()
            }))
        }
        if let email = primaryEmail, !email.isEmpty {
            actionRows.append(VoiceOverContactRow(title: "Email", subtitle: email, iconSystemName: "envelope.fill", action: { [weak self] in
                self?.openUrlString("mailto:\(email)")
            }))
        }
        if let peer = self.peer {
            actionRows.append(VoiceOverContactRow(title: "Open Telegram Profile", subtitle: peer.compactDisplayTitle, iconSystemName: "person.crop.circle", action: { [weak self] in
                self?.openTelegramProfile(peer)
            }))
        }
        if self.contactData.serializedVCard() != nil {
            actionRows.append(VoiceOverContactRow(title: "Share Contact", subtitle: self.presentationData.strings.Conversation_Contact, iconSystemName: "square.and.arrow.up", action: { [weak self] in
                self?.shareContact()
            }))
        }
        if !actionRows.isEmpty {
            sections.append(VoiceOverContactSection(rows: actionRows))
        }
        
        var detailRows: [VoiceOverContactRow] = []
        for phoneNumber in self.contactData.basicData.phoneNumbers {
            detailRows.append(VoiceOverContactRow(title: self.localizedLabel(phoneNumber.label, fallback: "Phone"), subtitle: phoneNumber.value, iconSystemName: nil, action: nil))
        }
        for email in self.contactData.emailAddresses {
            detailRows.append(VoiceOverContactRow(title: self.localizedLabel(email.label, fallback: "Email"), subtitle: email.value, iconSystemName: nil, action: nil))
        }
        if !self.contactData.organization.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            var organizationValue = self.contactData.organization
            let roleParts = [self.contactData.jobTitle, self.contactData.department].filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            if !roleParts.isEmpty {
                organizationValue += "\n" + roleParts.joined(separator: " • ")
            }
            detailRows.append(VoiceOverContactRow(title: "Organization", subtitle: organizationValue, iconSystemName: nil, action: nil))
        }
        for url in self.contactData.urls {
            detailRows.append(VoiceOverContactRow(title: self.localizedLabel(url.label, fallback: "Website"), subtitle: url.value, iconSystemName: nil, action: { [weak self] in
                self?.openExternalWebsite(url.value)
            }))
        }
        for address in self.contactData.addresses {
            detailRows.append(VoiceOverContactRow(title: self.localizedLabel(address.label, fallback: "Address"), subtitle: self.formattedAddress(address), iconSystemName: nil, action: nil))
        }
        for socialProfile in self.contactData.socialProfiles {
            let subtitle = [socialProfile.service, socialProfile.username, socialProfile.url].filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.joined(separator: "\n")
            detailRows.append(VoiceOverContactRow(title: self.localizedLabel(socialProfile.label, fallback: "Social Profile"), subtitle: subtitle, iconSystemName: nil, action: socialProfile.url.isEmpty ? nil : { [weak self] in
                self?.openExternalWebsite(socialProfile.url)
            }))
        }
        for profile in self.contactData.instantMessagingProfiles {
            let subtitle = [profile.service, profile.username].filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.joined(separator: "\n")
            detailRows.append(VoiceOverContactRow(title: self.localizedLabel(profile.label, fallback: "Instant Message"), subtitle: subtitle, iconSystemName: nil, action: nil))
        }
        if let birthdayDate = self.contactData.birthdayDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            formatter.timeStyle = .none
            detailRows.append(VoiceOverContactRow(title: "Birthday", subtitle: formatter.string(from: birthdayDate), iconSystemName: nil, action: nil))
        }
        if !self.contactData.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            detailRows.append(VoiceOverContactRow(title: "Note", subtitle: self.contactData.note, iconSystemName: nil, action: nil))
        }
        if detailRows.isEmpty {
            detailRows.append(VoiceOverContactRow(title: "No contact details", subtitle: nil, iconSystemName: nil, action: nil))
        }
        sections.append(VoiceOverContactSection(rows: detailRows))
        
        self.sections = sections
        self.tableView.reloadData()
    }
    
    private func localizedLabel(_ label: String, fallback: String) -> String {
        let normalized = label.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.isEmpty {
            return fallback
        }
        let localized = CNLabeledValue<NSString>.localizedString(forLabel: normalized)
        return localized.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? fallback : localized
    }
    
    private func formattedAddress(_ address: DeviceContactAddressData) -> String {
        return [
            address.street1,
            address.street2,
            address.postcode,
            address.city,
            address.state,
            address.country
        ]
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .joined(separator: "\n")
    }
    
    private func openUrlString(_ value: String) {
        guard let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let url = URL(string: encodedValue) else {
            self.presentUnavailableAlert()
            return
        }
        let application = self.context.sharedContext.applicationBindings
        if application.canOpenUrl(url.absoluteString) {
            application.openUrl(url.absoluteString)
        } else {
            self.presentUnavailableAlert()
        }
    }
    
    private func openExternalWebsite(_ value: String) {
        var link = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if link.isEmpty {
            self.presentUnavailableAlert()
            return
        }
        if !link.contains("://") {
            link = "https://\(link)"
        }
        self.openUrlString(link)
    }
    
    private func presentAddToContacts() {
        let contactController = CNContactViewController(forNewContact: self.contactData.asMutableCNContact())
        contactController.contactStore = CNContactStore()
        contactController.delegate = self
        contactController.navigationItem.largeTitleDisplayMode = .never
        
        let navigationController = UINavigationController(rootViewController: contactController)
        navigationController.modalPresentationStyle = .fullScreen
        navigationController.view.accessibilityViewIsModal = UIAccessibility.isVoiceOverRunning
        self.present(navigationController, animated: true)
    }
    
    private func shareContact() {
        guard let vCardString = self.contactData.serializedVCard(), let data = vCardString.data(using: .utf8) else {
            self.presentUnavailableAlert()
            return
        }
        let temporaryUrl = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).vcf")
        do {
            try data.write(to: temporaryUrl, options: .atomic)
            self.temporaryUrls.append(temporaryUrl)
            let controller = UIActivityViewController(activityItems: [temporaryUrl], applicationActivities: nil)
            if let popoverPresentationController = controller.popoverPresentationController {
                popoverPresentationController.barButtonItem = self.navigationItem.leftBarButtonItem
            }
            self.present(controller, animated: true)
        } catch {
            self.presentUnavailableAlert()
        }
    }
    
    private func openTelegramProfile(_ peer: EnginePeer) {
        guard let controller = self.context.sharedContext.makePeerInfoController(context: self.context, updatedPresentationData: nil, peer: peer._asPeer(), mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) else {
            self.presentUnavailableAlert()
            return
        }
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    private func presentUnavailableAlert() {
        let controller = UIAlertController(title: nil, message: self.presentationData.strings.Login_UnknownError, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: self.presentationData.strings.Common_OK, style: .default))
        self.present(controller, animated: true)
    }
}
