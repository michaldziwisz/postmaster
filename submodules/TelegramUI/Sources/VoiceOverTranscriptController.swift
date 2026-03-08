import UIKit
import TelegramPresentationData

final class VoiceOverTranscriptController: UIViewController, UIAdaptivePresentationControllerDelegate {
    private let presentationData: PresentationData
    private let transcriptText: String
    private let onDismiss: (() -> Void)?
    
    private let textView = UITextView()
    
    init(presentationData: PresentationData, transcriptText: String, onDismiss: (() -> Void)? = nil) {
        self.presentationData = presentationData
        self.transcriptText = transcriptText
        self.onDismiss = onDismiss
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = self.presentationData.strings.GroupBoost_AudioTranscription
        self.navigationItem.largeTitleDisplayMode = .never
        self.view.backgroundColor = .systemBackground
        self.view.accessibilityViewIsModal = UIAccessibility.isVoiceOverRunning
        self.presentationController?.delegate = self
        
        let backButtonItem = UIBarButtonItem(title: self.presentationData.strings.Common_Back, style: .plain, target: self, action: #selector(self.backPressed))
        backButtonItem.accessibilityLabel = self.presentationData.strings.Common_Back
        self.navigationItem.leftBarButtonItem = backButtonItem
        
        let copyButtonItem = UIBarButtonItem(title: self.presentationData.strings.Conversation_ContextMenuCopy, style: .plain, target: self, action: #selector(self.copyPressed))
        copyButtonItem.accessibilityLabel = self.presentationData.strings.Conversation_ContextMenuCopy
        self.navigationItem.rightBarButtonItem = copyButtonItem
        
        self.textView.translatesAutoresizingMaskIntoConstraints = false
        self.textView.backgroundColor = .systemBackground
        self.textView.font = UIFont.preferredFont(forTextStyle: .body)
        self.textView.adjustsFontForContentSizeCategory = true
        self.textView.isEditable = false
        self.textView.isSelectable = true
        self.textView.alwaysBounceVertical = true
        self.textView.text = self.transcriptText
        self.textView.accessibilityLabel = self.presentationData.strings.GroupBoost_AudioTranscription
        self.textView.accessibilityValue = self.transcriptText
        
        self.view.addSubview(self.textView)
        NSLayoutConstraint.activate([
            self.textView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 16.0),
            self.textView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -16.0),
            self.textView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 12.0),
            self.textView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -12.0)
        ])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.presentationController?.delegate = self
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .screenChanged, argument: self.textView)
        }
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
    
    @objc private func copyPressed() {
        UIPasteboard.general.string = self.transcriptText
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .announcement, argument: self.presentationData.strings.Conversation_TextCopied)
        }
    }
}
