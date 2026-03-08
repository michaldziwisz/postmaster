import Foundation
import UIKit
import SwiftSignalKit
import Postbox
import TelegramCore
import QuickLook
import Display
import TelegramPresentationData
import AccountContext
import SaveToCameraRoll
import PresentationDataUtils

private final class DocumentPreviewItem: NSObject, QLPreviewItem {
    private let url: URL
    private let title: String
    
    var previewItemURL: URL? {
        return self.url
    }
    
    var previewItemTitle: String? {
        return self.title
    }
    
    init(url: URL, title: String) {
        self.url = url
        self.title = title
    }
}

private final class DocumentActivityViewController: UIActivityViewController {
    private var tempFile: TempBoxFile?

    init(activityItems: [Any], applicationActivities: [UIActivity]?, tempFile: TempBoxFile?) {
        self.tempFile = tempFile
        super.init(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        if let tempFile = self.tempFile {
            TempBox.shared.dispose(tempFile)
        }
    }

    override func accessibilityPerformEscape() -> Bool {
        self.dismiss(animated: true)
        return true
    }
}

private final class CompactDocumentPreviewController: QLPreviewController, QLPreviewControllerDelegate, QLPreviewControllerDataSource {
    private let canShare: Bool
    private let strings: PresentationStrings
    
    private let item: DocumentPreviewItem
    
    private var tempFile: TempBoxFile?
    
    init(theme: PresentationTheme, strings: PresentationStrings, item: DocumentPreviewItem, tempFile: TempBoxFile?, canShare: Bool = true) {
        self.canShare = canShare
        self.strings = strings
        self.item = item
        self.tempFile = tempFile
        
        super.init(nibName: nil, bundle: nil)
        
        self.delegate = self
        self.dataSource = self

        let backButtonItem = UIBarButtonItem(title: strings.Common_Back, style: .plain, target: self, action: #selector(self.cancelPressed))
        backButtonItem.accessibilityLabel = strings.Common_Back
        self.navigationItem.leftBarButtonItem = backButtonItem
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        if let tempFile = self.tempFile {
            TempBox.shared.dispose(tempFile)
        }
        self.timer?.invalidate()
    }
    
    @objc private func cancelPressed() {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    override func accessibilityPerformEscape() -> Bool {
        self.cancelPressed()
        return true
    }
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return self.item
    }
    
    func previewControllerWillDismiss(_ controller: QLPreviewController) {
        self.cancelPressed()
    }
    
    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        //self.cancelPressed()
    }
    
    private var navigationBars: [UINavigationBar] = []
    private var toolbars: [UIView] = []
    private var observations : [NSKeyValueObservation] = []
    
    private var initialized = false
    private var timer: SwiftSignalKit.Timer?
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !self.canShare && !self.initialized {
            self.initialized = true
            
            self.timer = SwiftSignalKit.Timer(timeout: 0.01, repeat: true, completion: { [weak self] in
                self?.tick()
            }, queue: Queue.mainQueue())
            self.timer?.start()
        }
    }
    
    private func tick() {
        let (navigationBars, toolbars) = navigationAndToolbarsInSubviews(forView: self.view)
        self.navigationBars = navigationBars
        self.toolbars = toolbars
        
        if #available(iOS 16.0, *) {
            if let navigationController = self.children.first as? UINavigationController, let topController = navigationController.topViewController {
                topController.navigationItem.titleMenuProvider = nil
            }
            
            for toolbar in self.toolbars {
                toolbar.isHidden = true
            }
            
            if let navigationBar = navigationBars.first {
                let imageViews = imageViewsInSubviews(forView: navigationBar)
                for imageView in imageViews {
                    if imageView.frame.height > 4.0 {
                        imageView.isHidden = true
                        imageView.superview?.isUserInteractionEnabled = false
                    }
                }
            }
        } else {
            self.navigationItem.rightBarButtonItem = nil
            self.navigationItem.rightBarButtonItems = nil
            
            self.navigationController?.toolbar.isHidden = true
            
            for navigationBar in self.navigationBars {
                navigationBar.topItem?.rightBarButtonItem = nil
                navigationBar.topItem?.rightBarButtonItems = nil
            }
            
            for toolbar in self.toolbars {
                toolbar.isHidden = true
            }
        }
    }

    private func navigationAndToolbarsInSubviews(forView view: UIView) -> ([UINavigationBar], [UIView]) {
        var navigationBars: [UINavigationBar] = []
        var toolbars: [UIView] = []
        for subview in view.subviews {
            if let subview = subview as? UINavigationBar {
                navigationBars.append(subview)
            } else if let subview = subview as? UIToolbar {
                toolbars.append(subview)
            } else {
                let (subNavigationBars, subToolbars) = navigationAndToolbarsInSubviews(forView: subview)
                navigationBars.append(contentsOf: subNavigationBars)
                toolbars.append(contentsOf: subToolbars)
            }
        }
        return (navigationBars, toolbars)
    }
    
    private func imageViewsInSubviews(forView view: UIView) -> [UIView] {
        var result: [UIView] = []
        for subview in view.subviews {
            if let subview = subview as? UIImageView {
                result.append(subview)
            } else {
                let imageViews = imageViewsInSubviews(forView: subview)
                result.append(contentsOf: imageViews)
            }
        }
        return result
    }
}

private func preparedDocumentPreviewItem(path: String, fileName: String?, fallbackTitle: String) -> (item: DocumentPreviewItem, tempFile: TempBoxFile?) {
    let title = (fileName?.isEmpty == false ? fileName! : fallbackTitle)
    if let fileName, !fileName.isEmpty {
        let tempFile = TempBox.shared.file(path: path, fileName: fileName)
        let item = DocumentPreviewItem(url: URL(fileURLWithPath: tempFile.path), title: title)
        return (item, tempFile)
    } else {
        let item = DocumentPreviewItem(url: URL(fileURLWithPath: path), title: title)
        return (item, nil)
    }
}

private func makeDocumentLoadingOverlay(theme: PresentationTheme, present: @escaping (ViewController, Any?) -> Void, cancel: @escaping () -> Void) -> Disposable {
    return (Signal<Never, NoError> { _ in
        let controller = OverlayStatusController(theme: theme, type: .loading(cancelled: {
            cancel()
        }))
        present(controller, ViewControllerPresentationArguments(presentationAnimation: .modalSheet))
        return ActionDisposable { [weak controller] in
            Queue.mainQueue().async {
                controller?.dismiss()
            }
        }
    }
    |> runOn(Queue.mainQueue())
    |> delay(0.15, queue: Queue.mainQueue())).startStrict()
}

func presentDocumentPreviewController(rootController: UIViewController, context: AccountContext, theme: PresentationTheme, strings: PresentationStrings, fileReference: FileMediaReference, canShare: Bool) {
    let navigationBar = UINavigationBar.appearance(whenContainedInInstancesOf: [QLPreviewController.self])
    navigationBar.barTintColor = theme.rootController.navigationBar.opaqueBackgroundColor
    navigationBar.setBackgroundImage(generateImage(CGSize(width: 1.0, height: 1.0), rotatedContext: { size, context in
        context.setFillColor(theme.rootController.navigationBar.opaqueBackgroundColor.cgColor)
        context.fill(CGRect(origin: CGPoint(), size: size))
    }), for: .default)
    navigationBar.isTranslucent = true
    navigationBar.tintColor = theme.rootController.navigationBar.accentTextColor
    navigationBar.shadowImage = generateImage(CGSize(width: 1.0, height: 1.0), rotatedContext: { size, context in
        context.clear(CGRect(origin: CGPoint(), size: size))
        context.setFillColor(theme.rootController.navigationBar.separatorColor.cgColor)
        context.fill(CGRect(origin: CGPoint(), size: CGSize(width: 1.0, height: UIScreenPixel)))
    })
    navigationBar.titleTextAttributes = [NSAttributedString.Key.font: Font.semibold(17.0), NSAttributedString.Key.foregroundColor: theme.rootController.navigationBar.primaryTextColor]

    let file = fileReference.media

    let disposable = MetaDisposable()
    let progressDisposable = makeDocumentLoadingOverlay(theme: theme, present: { controller, _ in
        rootController.present(controller, animated: true)
    }, cancel: {
        disposable.set(nil)
    })

    disposable.set((fetchMediaData(context: context, postbox: context.account.postbox, userLocation: .other, mediaReference: fileReference.abstract)
    |> afterDisposed {
        Queue.mainQueue().async {
            progressDisposable.dispose()
        }
    }
    |> deliverOnMainQueue).startStrict(next: { state, _ in
        guard case let .data(data) = state, data.complete else {
            return
        }

        let preparedItem = preparedDocumentPreviewItem(path: data.path, fileName: file.fileName, fallbackTitle: file.fileName ?? strings.Message_File)
        progressDisposable.dispose()

        Queue.mainQueue().after(0.1, {
            if QLPreviewController.canPreview(preparedItem.item) {
                let controller = CompactDocumentPreviewController(theme: theme, strings: strings, item: preparedItem.item, tempFile: preparedItem.tempFile, canShare: canShare)
                rootController.present(controller, animated: true)
            } else if canShare, let url = preparedItem.item.previewItemURL {
                let controller = DocumentActivityViewController(activityItems: [url], applicationActivities: nil, tempFile: preparedItem.tempFile)
                if let popoverPresentationController = controller.popoverPresentationController {
                    popoverPresentationController.sourceView = rootController.view
                    popoverPresentationController.sourceRect = CGRect(x: rootController.view.bounds.midX, y: rootController.view.bounds.midY, width: 1.0, height: 1.0)
                }
                rootController.present(controller, animated: true)
            } else {
                if let tempFile = preparedItem.tempFile {
                    TempBox.shared.dispose(tempFile)
                }
                let controller = UIAlertController(title: nil, message: "This file can't be previewed in the app.", preferredStyle: .alert)
                controller.addAction(UIAlertAction(title: strings.Common_OK, style: .default))
                rootController.present(controller, animated: true)
            }
        })
    }))
}
