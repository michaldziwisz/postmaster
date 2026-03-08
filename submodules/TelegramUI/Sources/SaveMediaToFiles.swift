import Foundation
import AVFoundation
import Display
import SwiftSignalKit
import Postbox
import TelegramCore
import AccountContext
import OverlayStatusController
import LegacyMediaPickerUI
import SaveToCameraRoll
import PresentationDataUtils

private func fileNameForExport(fileReference: FileMediaReference, sourcePath: String) -> String {
    let originalFileName = fileReference.media.fileName?.trimmingCharacters(in: .whitespacesAndNewlines)

    var fileExtension: String?
    if let originalFileName, let dotIndex = originalFileName.lastIndex(of: ".") {
        fileExtension = String(originalFileName[originalFileName.index(after: dotIndex)...])
    }

    var title: String?
    var performer: String?
    for attribute in fileReference.media.attributes {
        if case let .Audio(_, _, titleValue, performerValue, _) = attribute {
            if let titleValue, !titleValue.isEmpty {
                title = titleValue
            }
            if let performerValue, !performerValue.isEmpty {
                performer = performerValue
            }
        }
    }

    if title != nil || performer != nil || fileReference.media.isMusic || fileReference.media.isVoice {
        let audioAsset = AVURLAsset(url: URL(fileURLWithPath: sourcePath))

        var resolvedTitle = title
        var resolvedPerformer = performer
        if resolvedTitle == nil || resolvedPerformer == nil {
            for metadata in audioAsset.commonMetadata {
                if resolvedPerformer == nil, metadata.commonKey == .commonKeyArtist {
                    resolvedPerformer = metadata.stringValue
                }
                if resolvedTitle == nil, metadata.commonKey == .commonKeyTitle {
                    resolvedTitle = metadata.stringValue
                }
            }
        }

        var nameComponents: [String] = []
        if let resolvedPerformer, !resolvedPerformer.isEmpty {
            nameComponents.append(resolvedPerformer)
        }
        if let resolvedTitle, !resolvedTitle.isEmpty {
            nameComponents.append(resolvedTitle)
        }

        if !nameComponents.isEmpty {
            let resolvedExtension = (fileExtension?.isEmpty == false ? fileExtension! : "mp3")
            return "\(nameComponents.joined(separator: " – ")).\(resolvedExtension)"
        }
    }

    if let originalFileName, !originalFileName.isEmpty {
        return originalFileName
    }

    if let fileExtension, !fileExtension.isEmpty {
        return "file.\(fileExtension)"
    } else {
        return "file"
    }
}

func saveMediaToFiles(context: AccountContext, fileReference: FileMediaReference, present: @escaping (ViewController, Any?) -> Void) -> Disposable {
    var signal = fetchMediaData(context: context, postbox: context.account.postbox, userLocation: .other, mediaReference: fileReference.abstract)
    
    var cancelImpl: (() -> Void)?
    let presentationData = context.sharedContext.currentPresentationData.with { $0 }
    let progressSignal = Signal<Never, NoError> { subscriber in
        let controller = OverlayStatusController(theme: presentationData.theme, type: .loading(cancelled: {
            cancelImpl?()
        }))
        present(controller, ViewControllerPresentationArguments(presentationAnimation: .modalSheet))
        return ActionDisposable { [weak controller] in
            Queue.mainQueue().async() {
                controller?.dismiss()
            }
        }
    }
    |> runOn(Queue.mainQueue())
    |> delay(0.15, queue: Queue.mainQueue())
    
    let progressDisposable = progressSignal.startStrict()
    
    let disposable = MetaDisposable()
    signal = signal
    |> afterDisposed {
        Queue.mainQueue().async {
            progressDisposable.dispose()
        }
    }
    cancelImpl = { [weak disposable] in
        disposable?.set(nil)
    }
    disposable.set((signal
    |> deliverOnMainQueue).startStrict(next: { state, _ in
        switch state {
        case .progress:
            break
        case let .data(data):
            if data.complete {
                let tempFile = TempBox.shared.tempFile(fileName: fileNameForExport(fileReference: fileReference, sourcePath: data.path))
                try? FileManager.default.removeItem(atPath: tempFile.path)
                if (try? FileManager.default.linkItem(atPath: data.path, toPath: tempFile.path)) == nil {
                    let _ = try? FileManager.default.copyItem(atPath: data.path, toPath: tempFile.path)
                }

                var didCleanup = false
                let cleanup: () -> Void = {
                    guard !didCleanup else {
                        return
                    }
                    didCleanup = true
                    TempBox.shared.dispose(tempFile)
                }

                let controller = legacyICloudFilePicker(theme: presentationData.theme, mode: .export, url: URL(fileURLWithPath: tempFile.path), documentTypes: [], forceDarkTheme: false, dismissed: {
                    cleanup()
                }, completion: { _ in
                    cleanup()
                })
                present(controller, nil)
            }
        }
    }))
    
    return disposable
}
