import UIKit
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import AccountContext
import TranslateUI
import PremiumUI

private enum VoiceOverChatInfoRow {
    case action(title: String, subtitle: String?, iconSystemName: String?, action: () -> Void)
    case info(title: String, subtitle: String?)
    case toggle(id: String, title: String, subtitle: String?, isOn: Bool, isEnabled: Bool, valueChanged: (Bool) -> Void)
}

private struct VoiceOverChatInfoSection {
    let header: String?
    let rows: [VoiceOverChatInfoRow]
}

private final class VoiceOverChatInfoSwitchCell: UITableViewCell {
    let toggleSwitch = UISwitch(frame: .zero)
    var valueChanged: ((Bool) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.accessoryView = self.toggleSwitch
        self.toggleSwitch.addTarget(self, action: #selector(self.switchValueChanged), for: .valueChanged)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func switchValueChanged() {
        self.valueChanged?(self.toggleSwitch.isOn)
    }
}

final class VoiceOverChatInfoController: UITableViewController {
    private let context: AccountContext
    private let presentationData: PresentationData
    private let peerId: EnginePeer.Id
    private let threadId: Int64?
    private let onSearch: (() -> Void)?

    private let stateDisposable = MetaDisposable()

    private var sections: [VoiceOverChatInfoSection] = []
    private var currentPeer: Peer?

    init(
        context: AccountContext,
        presentationData: PresentationData,
        peerId: EnginePeer.Id,
        threadId: Int64?,
        onSearch: (() -> Void)? = nil
    ) {
        self.context = context
        self.presentationData = presentationData
        self.peerId = peerId
        self.threadId = threadId
        self.onSearch = onSearch

        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.stateDisposable.dispose()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = self.presentationData.strings.KeyCommand_ChatInfo
        self.navigationItem.largeTitleDisplayMode = .never
        self.view.backgroundColor = .systemBackground
        self.view.accessibilityViewIsModal = UIAccessibility.isVoiceOverRunning

        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 60.0
        self.tableView.cellLayoutMarginsFollowReadableWidth = true

        self.bindState()
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
        let row = self.sections[indexPath.section].rows[indexPath.row]

        switch row {
        case let .toggle(id, title, subtitle, isOn, isEnabled, valueChanged):
            let identifier = "VoiceOverChatInfoSwitchCell.\(id)"
            let cell: VoiceOverChatInfoSwitchCell
            if let current = tableView.dequeueReusableCell(withIdentifier: identifier) as? VoiceOverChatInfoSwitchCell {
                cell = current
            } else {
                cell = VoiceOverChatInfoSwitchCell(style: .subtitle, reuseIdentifier: identifier)
            }

            cell.textLabel?.text = title
            cell.textLabel?.numberOfLines = 0
            cell.detailTextLabel?.text = subtitle
            cell.detailTextLabel?.numberOfLines = 0
            cell.imageView?.image = nil
            cell.selectionStyle = .none
            cell.accessoryType = .none
            cell.isAccessibilityElement = false

            cell.toggleSwitch.isOn = isOn
            cell.toggleSwitch.isEnabled = isEnabled
            cell.toggleSwitch.accessibilityLabel = title
            cell.toggleSwitch.accessibilityHint = subtitle
            cell.valueChanged = valueChanged

            return cell

        case let .action(title, subtitle, iconSystemName, _):
            let identifier = "VoiceOverChatInfoActionCell"
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell(style: .subtitle, reuseIdentifier: identifier)

            cell.textLabel?.text = title
            cell.textLabel?.numberOfLines = 0
            cell.detailTextLabel?.text = subtitle
            cell.detailTextLabel?.numberOfLines = 0
            if let iconSystemName {
                cell.imageView?.image = UIImage(systemName: iconSystemName)
                cell.imageView?.tintColor = self.view.tintColor
            } else {
                cell.imageView?.image = nil
            }
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
            cell.isAccessibilityElement = true
            cell.accessibilityLabel = self.accessibilityLabel(title: title, subtitle: subtitle)
            cell.accessibilityTraits = [.button]

            return cell

        case let .info(title, subtitle):
            let identifier = "VoiceOverChatInfoInfoCell"
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell(style: .subtitle, reuseIdentifier: identifier)

            cell.textLabel?.text = title
            cell.textLabel?.numberOfLines = 0
            cell.detailTextLabel?.text = subtitle
            cell.detailTextLabel?.numberOfLines = 0
            cell.imageView?.image = nil
            cell.accessoryType = .none
            cell.selectionStyle = .none
            cell.isAccessibilityElement = true
            cell.accessibilityLabel = self.accessibilityLabel(title: title, subtitle: subtitle)
            cell.accessibilityTraits = [.staticText]

            return cell
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch self.sections[indexPath.section].rows[indexPath.row] {
        case let .action(_, _, _, action):
            action()
        case .info, .toggle:
            break
        }
    }

    override func accessibilityPerformEscape() -> Bool {
        self.navigationController?.popViewController(animated: true)
        return true
    }

    private func bindState() {
        let translationSettings = self.context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.translationSettings])
        |> map { sharedData -> TranslationSettings in
            return sharedData.entries[ApplicationSpecificSharedDataKeys.translationSettings]?.get(TranslationSettings.self) ?? TranslationSettings.defaultSettings
        }
        |> distinctUntilChanged

        let isPremium = self.context.engine.data.subscribe(TelegramEngine.EngineData.Item.Peer.Peer(id: self.context.account.peerId))
        |> map { peer -> Bool in
            return peer?.isPremium ?? false
        }
        |> distinctUntilChanged

        let peer = self.context.engine.data.subscribe(TelegramEngine.EngineData.Item.Peer.Peer(id: self.peerId))
        let aboutText = self.context.engine.data.subscribe(TelegramEngine.EngineData.Item.Peer.AboutText(id: self.peerId))
        let autoTranslateEnabled = self.context.engine.data.subscribe(TelegramEngine.EngineData.Item.Peer.AutoTranslateEnabled(id: self.peerId))
        |> distinctUntilChanged
        let currentChatTranslationState = chatTranslationState(context: self.context, peerId: self.peerId, threadId: self.threadId)
        |> distinctUntilChanged

        self.stateDisposable.set((combineLatest(
            queue: .mainQueue(),
            peer,
            aboutText,
            translationSettings,
            isPremium,
            autoTranslateEnabled,
            currentChatTranslationState
        )
        |> deliverOnMainQueue).startStrict(next: { [weak self] peer, aboutText, translationSettings, isPremium, autoTranslateEnabled, currentChatTranslationState in
            guard let self else {
                return
            }
            self.currentPeer = peer
            self.reloadSections(
                peer: peer,
                aboutText: aboutText.knownValue ?? nil,
                translationSettings: translationSettings,
                isPremium: isPremium,
                autoTranslateEnabled: autoTranslateEnabled,
                currentChatTranslationState: currentChatTranslationState
            )
        }))
    }

    private func reloadSections(
        peer: Peer?,
        aboutText: String?,
        translationSettings: TranslationSettings,
        isPremium: Bool,
        autoTranslateEnabled: Bool,
        currentChatTranslationState: ChatTranslationState?
    ) {
        var sections: [VoiceOverChatInfoSection] = []

        var actionRows: [VoiceOverChatInfoRow] = []
        if let onSearch = self.onSearch {
            actionRows.append(.action(
                title: self.presentationData.strings.Conversation_Search,
                subtitle: nil,
                iconSystemName: "magnifyingglass",
                action: { [weak self] in
                    self?.popAndPerformSearch(onSearch)
                }
            ))
        }
        if !actionRows.isEmpty {
            sections.append(VoiceOverChatInfoSection(header: nil, rows: actionRows))
        }

        var translationRows: [VoiceOverChatInfoRow] = []
        translationRows.append(.toggle(
            id: "translate-chats",
            title: self.presentationData.strings.Localization_TranslateEntireChat,
            subtitle: isPremium ? nil : "Premium required",
            isOn: isPremium ? translationSettings.translateChats : false,
            isEnabled: isPremium,
            valueChanged: { [weak self] value in
                self?.updateTranslateChatsEnabled(value)
            }
        ))

        if let currentChatTranslationState {
            translationRows.append(.toggle(
                id: "chat-translation",
                title: "Show translated messages",
                subtitle: self.translationLanguageSubtitle(for: currentChatTranslationState),
                isOn: currentChatTranslationState.isEnabled,
                isEnabled: true,
                valueChanged: { [weak self] value in
                    self?.updateCurrentChatTranslationEnabled(value)
                }
            ))
        }

        if let channel = peer as? TelegramChannel {
            let premiumConfiguration = PremiumConfiguration.with(appConfiguration: self.context.currentAppConfiguration.with { $0 })
            let requiredLevel = BoostSubject.autoTranslate.requiredLevel(group: false, context: self.context, configuration: premiumConfiguration)
            let channelBoostLevel = channel.approximateBoostLevel ?? 0
            let isChannelAutoTranslateAvailable = channelBoostLevel >= requiredLevel
            translationRows.append(.toggle(
                id: "channel-auto-translation",
                title: self.presentationData.strings.Channel_Info_AutoTranslate,
                subtitle: isChannelAutoTranslateAvailable ? "Channel default" : "Requires boost level \(requiredLevel)",
                isOn: autoTranslateEnabled,
                isEnabled: isChannelAutoTranslateAvailable,
                valueChanged: { [weak self] value in
                    self?.updateChannelAutoTranslationEnabled(value)
                }
            ))
        }

        if !translationRows.isEmpty {
            sections.append(VoiceOverChatInfoSection(header: self.presentationData.strings.Localization_TranslateMessages, rows: translationRows))
        }

        var detailRows: [VoiceOverChatInfoRow] = []
        if let peer {
            detailRows.append(.info(title: self.presentationData.strings.KeyCommand_ChatInfo, subtitle: self.peerDisplayTitle(peer)))

            if let addressName = peer.addressName, !addressName.isEmpty {
                detailRows.append(.info(title: "Username", subtitle: "@\(addressName)"))
            }

            if let telegramUser = peer as? TelegramUser, let phone = telegramUser.phone, !phone.isEmpty {
                detailRows.append(.info(title: "Phone", subtitle: phone))
            }
        }

        if let aboutText {
            let trimmedAbout = aboutText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedAbout.isEmpty {
                detailRows.append(.info(title: "Description", subtitle: aboutText))
            }
        }

        if detailRows.isEmpty {
            detailRows.append(.info(title: self.presentationData.strings.Login_UnknownError, subtitle: nil))
        }
        sections.append(VoiceOverChatInfoSection(header: nil, rows: detailRows))

        self.sections = sections
        if let peer {
            self.title = self.peerDisplayTitle(peer)
        } else {
            self.title = self.presentationData.strings.KeyCommand_ChatInfo
        }
        self.tableView.reloadData()
    }

    private func updateTranslateChatsEnabled(_ value: Bool) {
        let _ = updateTranslationSettingsInteractively(accountManager: self.context.sharedContext.accountManager, { current in
            var updated = current.withUpdatedTranslateChats(value)
            if !updated.showTranslate && !updated.translateChats {
                updated = updated.withUpdatedIgnoredLanguages(nil)
            }
            return updated
        }).start()
    }

    private func updateCurrentChatTranslationEnabled(_ value: Bool) {
        let _ = updateChatTranslationStateInteractively(engine: self.context.engine, peerId: self.peerId, threadId: self.threadId, { current in
            return current?.withIsEnabled(value)
        }).start()
    }

    private func updateChannelAutoTranslationEnabled(_ value: Bool) {
        let _ = self.context.engine.peers.toggleAutoTranslation(peerId: self.peerId, enabled: value).start()
    }

    private func popAndPerformSearch(_ action: @escaping () -> Void) {
        if let navigationController = self.navigationController {
            navigationController.popViewController(animated: true)
            Queue.mainQueue().after(0.35, {
                action()
            })
        } else {
            action()
        }
    }

    private func accessibilityLabel(title: String, subtitle: String?) -> String {
        guard let subtitle, !subtitle.isEmpty else {
            return title
        }
        return "\(title), \(subtitle)"
    }

    private func peerDisplayTitle(_ peer: Peer) -> String {
        if peer.id == self.context.account.peerId {
            return self.presentationData.strings.DialogList_SavedMessages
        }
        return EnginePeer(peer).displayTitle(strings: self.presentationData.strings, displayOrder: self.presentationData.nameDisplayOrder)
    }

    private func translationLanguageSubtitle(for state: ChatTranslationState) -> String? {
        let code = self.normalizedLanguageCode(state.toLang)
        guard let code else {
            return nil
        }
        let locale = Locale(identifier: "en")
        return locale.localizedString(forLanguageCode: code)?.capitalized
    }

    private func normalizedLanguageCode(_ code: String?) -> String? {
        guard let code, !code.isEmpty else {
            return nil
        }
        let rawSuffix = "-raw"
        if code.hasSuffix(rawSuffix) {
            return String(code.dropLast(rawSuffix.count))
        }
        return code
    }
}
