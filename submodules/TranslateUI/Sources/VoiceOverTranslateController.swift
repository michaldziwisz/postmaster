import UIKit
import SwiftSignalKit
import TelegramCore
import AccountContext
import TelegramPresentationData

private struct VoiceOverTranslateRow {
    let title: String
    let subtitle: String?
    let action: (() -> Void)?
}

private struct VoiceOverTranslateSection {
    let header: String?
    let rows: [VoiceOverTranslateRow]
}

private final class VoiceOverTranslationLanguageController: UITableViewController {
    private let presentationData: PresentationData
    private let selectedLanguage: String
    private let languages: [(String, String, String)]
    private let onSelected: (String) -> Void
    
    init(presentationData: PresentationData, selectedLanguage: String, onSelected: @escaping (String) -> Void) {
        self.presentationData = presentationData
        self.selectedLanguage = selectedLanguage
        self.onSelected = onSelected
        
        let interfaceLanguageCode = presentationData.strings.baseLanguageCode
        let enLocale = Locale(identifier: "en")
        var languages: [(String, String, String)] = []
        var addedLanguages = Set<String>()
        
        for code in popularTranslationLanguages {
            if let title = enLocale.localizedString(forLanguageCode: code) {
                let languageLocale = Locale(identifier: code)
                let subtitle = languageLocale.localizedString(forLanguageCode: code) ?? title
                let value = (code, title.capitalized, subtitle.capitalized)
                if code == interfaceLanguageCode {
                    languages.insert(value, at: 0)
                } else {
                    languages.append(value)
                }
                addedLanguages.insert(code)
            }
        }
        
        for code in supportedTranslationLanguages {
            if addedLanguages.contains(code) {
                continue
            }
            if let title = enLocale.localizedString(forLanguageCode: code) {
                let languageLocale = Locale(identifier: code)
                let subtitle = languageLocale.localizedString(forLanguageCode: code) ?? title
                let value = (code, title.capitalized, subtitle.capitalized)
                if code == interfaceLanguageCode {
                    languages.insert(value, at: 0)
                } else {
                    languages.append(value)
                }
            }
        }
        
        self.languages = languages
        super.init(style: .insetGrouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = self.presentationData.strings.Translate_ChangeLanguage
        self.navigationItem.largeTitleDisplayMode = .never
        self.view.backgroundColor = .systemBackground
        self.view.accessibilityViewIsModal = UIAccessibility.isVoiceOverRunning
        
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 56.0
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .screenChanged, argument: self.tableView)
        }
    }
    
    override func accessibilityPerformEscape() -> Bool {
        _ = self.navigationController?.popViewController(animated: true)
        return true
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.languages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "VoiceOverTranslationLanguageCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell(style: .subtitle, reuseIdentifier: identifier)
        let language = self.languages[indexPath.row]
        
        cell.textLabel?.text = language.1
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.text = language.2
        cell.detailTextLabel?.numberOfLines = 0
        cell.accessoryType = language.0 == self.selectedLanguage ? .checkmark : .none
        cell.selectionStyle = .default
        cell.isAccessibilityElement = true
        cell.accessibilityLabel = language.2 == language.1 ? language.1 : "\(language.1), \(language.2)"
        cell.accessibilityTraits = language.0 == self.selectedLanguage ? [.button, .selected] : [.button]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.onSelected(self.languages[indexPath.row].0)
        _ = self.navigationController?.popViewController(animated: true)
    }
}

final class VoiceOverTranslateController: UITableViewController, UIAdaptivePresentationControllerDelegate {
    private let context: AccountContext
    private let presentationData: PresentationData
    private let text: String
    private let canCopy: Bool
    private let ignoredLanguages: [String]?
    private let onDismiss: (() -> Void)?
    
    private var fromLanguage: String?
    private var toLanguage: String
    private var translatedText: String?
    private var isLoadingTranslation = false
    
    private let translationDisposable = MetaDisposable()
    
    init(
        context: AccountContext,
        presentationData: PresentationData,
        text: String,
        canCopy: Bool,
        fromLanguage: String?,
        toLanguage: String,
        ignoredLanguages: [String]? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.context = context
        self.presentationData = presentationData
        self.text = text
        self.canCopy = canCopy
        self.fromLanguage = fromLanguage
        self.toLanguage = toLanguage
        self.ignoredLanguages = ignoredLanguages
        self.onDismiss = onDismiss
        
        super.init(style: .insetGrouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.translationDisposable.dispose()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = self.presentationData.strings.Translate_Title
        self.navigationItem.largeTitleDisplayMode = .never
        self.view.backgroundColor = .systemBackground
        self.view.accessibilityViewIsModal = UIAccessibility.isVoiceOverRunning
        self.presentationController?.delegate = self
        
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 64.0
        self.tableView.cellLayoutMarginsFollowReadableWidth = true
        
        let backButtonItem = UIBarButtonItem(title: self.presentationData.strings.Common_Back, style: .plain, target: self, action: #selector(self.backPressed))
        backButtonItem.accessibilityLabel = self.presentationData.strings.Common_Back
        self.navigationItem.leftBarButtonItem = backButtonItem
        
        self.reloadTranslation()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.presentationController?.delegate = self
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .screenChanged, argument: self.tableView)
        }
    }
    
    override func accessibilityPerformEscape() -> Bool {
        self.backPressed()
        return true
    }
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.onDismiss?()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.sections.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sections[section].header
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sections[section].rows.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "VoiceOverTranslateCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell(style: .subtitle, reuseIdentifier: identifier)
        let row = self.sections[indexPath.section].rows[indexPath.row]
        
        cell.textLabel?.text = row.title
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.text = row.subtitle
        cell.detailTextLabel?.numberOfLines = 0
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
    
    private var sections: [VoiceOverTranslateSection] {
        var sections: [VoiceOverTranslateSection] = []
        
        let originalSection = VoiceOverTranslateSection(
            header: self.presentationData.strings.Translate_Languages_Original,
            rows: [
                VoiceOverTranslateRow(title: "Language", subtitle: self.languageDisplayName(for: self.fromLanguage) ?? "Automatic", action: nil),
                VoiceOverTranslateRow(title: "Text", subtitle: self.text, action: nil)
            ]
        )
        sections.append(originalSection)
        
        let translatedSubtitle: String
        if self.isLoadingTranslation {
            translatedSubtitle = self.presentationData.strings.Channel_NotificationLoading
        } else if let translatedText = self.translatedText, !translatedText.isEmpty {
            translatedSubtitle = translatedText
        } else {
            translatedSubtitle = self.presentationData.strings.Login_UnknownError
        }
        
        let translationSection = VoiceOverTranslateSection(
            header: self.presentationData.strings.Translate_Languages_Translation,
            rows: [
                VoiceOverTranslateRow(title: self.presentationData.strings.Translate_ChangeLanguage, subtitle: self.languageDisplayName(for: self.toLanguage), action: { [weak self] in
                    self?.openLanguageSelection()
                }),
                VoiceOverTranslateRow(title: "Translation", subtitle: translatedSubtitle, action: nil)
            ]
        )
        sections.append(translationSection)
        
        if self.canCopy, let translatedText = self.translatedText, !translatedText.isEmpty {
            sections.append(VoiceOverTranslateSection(
                header: nil,
                rows: [
                    VoiceOverTranslateRow(title: self.presentationData.strings.Translate_CopyTranslation, subtitle: translatedText, action: { [weak self] in
                        self?.copyTranslation()
                    })
                ]
            ))
        }
        
        return sections
    }
    
    @objc private func backPressed() {
        let onDismiss = self.onDismiss
        self.dismiss(animated: true, completion: onDismiss)
    }
    
    private func languageDisplayName(for code: String?) -> String? {
        guard let code, !code.isEmpty else {
            return nil
        }
        var interfaceLanguageCode = self.presentationData.strings.baseLanguageCode
        let rawSuffix = "-raw"
        if interfaceLanguageCode.hasSuffix(rawSuffix) {
            interfaceLanguageCode = String(interfaceLanguageCode.dropLast(rawSuffix.count))
        }
        let locale = Locale(identifier: interfaceLanguageCode)
        return locale.localizedString(forLanguageCode: code) ?? Locale(identifier: "en").localizedString(forLanguageCode: code)?.capitalized ?? code
    }
    
    private func reloadTranslation() {
        self.isLoadingTranslation = true
        self.translatedText = nil
        self.tableView.reloadData()
        
        let translationConfiguration = TranslationConfiguration.with(appConfiguration: self.context.currentAppConfiguration.with { $0 })
        let signal: Signal<(String, [MessageTextEntity])?, TranslationError>
        switch translationConfiguration.manual {
        case .alternative:
            signal = alternativeTranslateText(text: self.text, fromLang: self.fromLanguage, toLang: self.toLanguage)
        default:
            signal = self.context.engine.messages.translate(text: self.text, toLang: self.toLanguage)
        }
        
        self.translationDisposable.set((signal
        |> deliverOnMainQueue).start(next: { [weak self] result in
            guard let self else {
                return
            }
            self.isLoadingTranslation = false
            self.translatedText = result?.0
            self.tableView.reloadData()
            if UIAccessibility.isVoiceOverRunning {
                UIAccessibility.post(notification: .layoutChanged, argument: self.tableView)
            }
        }, error: { [weak self] _ in
            guard let self else {
                return
            }
            self.isLoadingTranslation = false
            self.translatedText = nil
            self.tableView.reloadData()
            if UIAccessibility.isVoiceOverRunning {
                UIAccessibility.post(notification: .announcement, argument: self.presentationData.strings.Login_UnknownError)
            }
        }))
    }
    
    private func openLanguageSelection() {
        let controller = VoiceOverTranslationLanguageController(
            presentationData: self.presentationData,
            selectedLanguage: self.toLanguage,
            onSelected: { [weak self] code in
                guard let self else {
                    return
                }
                let normalizedCode = normalizeTranslationLanguage(code)
                guard normalizedCode != self.toLanguage else {
                    return
                }
                self.toLanguage = normalizedCode
                self.reloadTranslation()
            }
        )
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    private func copyTranslation() {
        guard let translatedText = self.translatedText, !translatedText.isEmpty else {
            return
        }
        UIPasteboard.general.string = translatedText
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .announcement, argument: self.presentationData.strings.Conversation_TextCopied)
        }
    }
}

private func topPresentingViewController(from controller: UIViewController?) -> UIViewController? {
    if let navigationController = controller as? UINavigationController {
        return topPresentingViewController(from: navigationController.visibleViewController ?? navigationController.topViewController ?? navigationController)
    }
    if let tabBarController = controller as? UITabBarController {
        return topPresentingViewController(from: tabBarController.selectedViewController ?? tabBarController)
    }
    if let presentedViewController = controller?.presentedViewController {
        return topPresentingViewController(from: presentedViewController)
    }
    return controller
}

func presentVoiceOverTranslateScreen(
    context: AccountContext,
    text: String,
    canCopy: Bool,
    fromLanguage: String?,
    toLanguage: String,
    ignoredLanguages: [String]? = nil,
    wasDismissed: (() -> Void)? = nil
) -> Bool {
    let presentationData = context.sharedContext.currentPresentationData.with { $0 }
    let mainController = context.sharedContext.mainWindow?.viewController as? UIViewController
    guard let presentingController = topPresentingViewController(from: mainController) else {
        return false
    }
    
    let controller = VoiceOverTranslateController(
        context: context,
        presentationData: presentationData,
        text: text,
        canCopy: canCopy,
        fromLanguage: fromLanguage,
        toLanguage: toLanguage,
        ignoredLanguages: ignoredLanguages,
        onDismiss: wasDismissed
    )
    let navigationController = UINavigationController(rootViewController: controller)
    navigationController.modalPresentationStyle = .pageSheet
    presentingController.present(navigationController, animated: true)
    return true
}
