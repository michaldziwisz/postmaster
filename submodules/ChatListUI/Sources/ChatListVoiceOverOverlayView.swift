import Foundation
import UIKit
import TelegramCore
import TelegramPresentationData

final class ChatListVoiceOverOverlayView: UIView {
    struct Actions {
        var openEntry: ((ChatListNodeEntry) -> Void)?
        var activateSearch: (() -> Void)?
        
        init(openEntry: ((ChatListNodeEntry) -> Void)? = nil, activateSearch: (() -> Void)? = nil) {
            self.openEntry = openEntry
            self.activateSearch = activateSearch
        }
    }
    
    private struct Row {
        var stableId: ChatListNodeEntryId
        var entry: ChatListNodeEntry
    }
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var rows: [Row] = []
    private var presentationData: PresentationData?
    
    var actions = Actions()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.isAccessibilityElement = false
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 64.0
        self.tableView.alwaysBounceVertical = true
        self.addSubview(self.tableView)
        
        NSLayoutConstraint.activate([
            self.tableView.topAnchor.constraint(equalTo: self.topAnchor),
            self.tableView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updatePresentationData(_ presentationData: PresentationData) {
        self.presentationData = presentationData
        self.backgroundColor = presentationData.theme.chatList.backgroundColor
        self.tableView.backgroundColor = presentationData.theme.chatList.backgroundColor
        self.tableView.separatorColor = presentationData.theme.chatList.itemSeparatorColor
        self.tableView.reloadData()
    }
    
    func updateEntries(_ entries: [ChatListNodeEntry]) {
        let newRows = self.makeRows(from: entries)
        
        let previousStableIds = self.rows.map(\.stableId)
        let newStableIds = newRows.map(\.stableId)
        if previousStableIds == newStableIds {
            self.rows = newRows
            return
        }
        
        self.rows = newRows
        UIView.performWithoutAnimation {
            self.tableView.reloadData()
            self.tableView.layoutIfNeeded()
        }
    }
    
    private func makeRows(from entries: [ChatListNodeEntry]) -> [Row] {
        var result: [Row] = []
        result.reserveCapacity(entries.count)
        
        for entry in entries {
            switch entry {
            case .PeerEntry, .ContactEntry, .AdditionalCategory:
                result.append(Row(stableId: entry.stableId, entry: entry))
            case .HeaderEntry:
                result.append(Row(stableId: entry.stableId, entry: entry))
            case .HoleEntry:
                break
            case .GroupReferenceEntry, .ArchiveIntro, .EmptyIntro, .SectionHeader:
                break
            }
        }
        
        return result
    }
    
    private func resolveRow(_ row: Row, presentationData: PresentationData) -> (title: String, subtitle: String?, accessibilityLabel: String, hint: String?, traits: UIAccessibilityTraits) {
        switch row.entry {
        case .HeaderEntry:
            let title = presentationData.strings.Common_Search
            return (title, nil, title, nil, [.searchField])
        case let .PeerEntry(peerEntry):
            let title: String
            if let peer = peerEntry.peer.chatMainPeer {
                title = peer.displayTitle(strings: presentationData.strings, displayOrder: presentationData.nameDisplayOrder)
            } else {
                title = presentationData.strings.User_DeletedAccount
            }
            
            let subtitle = peerEntry.messages.first?.text.trimmingCharacters(in: .whitespacesAndNewlines)
            var accessibilityLabel = title
            if let subtitle, !subtitle.isEmpty {
                accessibilityLabel.append(". ")
                accessibilityLabel.append(subtitle)
            }
            
            var traits: UIAccessibilityTraits = [.button]
            if let readState = peerEntry.readState, readState.count > 0 {
                traits.insert(.updatesFrequently)
            }
            
            return (title, subtitle, accessibilityLabel, presentationData.strings.VoiceOver_Chat_OpenHint, traits)
        case let .ContactEntry(contactEntry):
            let title = contactEntry.peer.displayTitle(strings: presentationData.strings, displayOrder: presentationData.nameDisplayOrder)
            return (title, nil, title, presentationData.strings.VoiceOver_Chat_OpenHint, [.button])
        case let .AdditionalCategory(_, _, title, _, _, _, _):
            return (title, nil, title, presentationData.strings.VoiceOver_Chat_OpenHint, [.button])
        case .HoleEntry:
            return ("", nil, "", nil, [.staticText])
        case .GroupReferenceEntry, .ArchiveIntro, .EmptyIntro, .SectionHeader:
            return ("", nil, "", nil, [.staticText])
        }
    }
}

extension ChatListVoiceOverOverlayView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.rows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        if let current = tableView.dequeueReusableCell(withIdentifier: "Cell") {
            cell = current
        } else {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
        }
        
        cell.textLabel?.numberOfLines = 1
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        
        cell.detailTextLabel?.numberOfLines = 2
        cell.detailTextLabel?.font = UIFont.preferredFont(forTextStyle: .caption1)
        cell.detailTextLabel?.adjustsFontForContentSizeCategory = true
        
        cell.selectionStyle = .default
        cell.isAccessibilityElement = true
        
        guard indexPath.row >= 0, indexPath.row < self.rows.count else {
            cell.textLabel?.text = ""
            cell.detailTextLabel?.text = nil
            cell.accessibilityLabel = ""
            cell.accessibilityTraits = [.staticText]
            return cell
        }
        
        guard let presentationData = self.presentationData else {
            cell.textLabel?.text = ""
            cell.detailTextLabel?.text = nil
            cell.accessibilityLabel = ""
            cell.accessibilityTraits = [.staticText]
            return cell
        }
        
        let row = self.rows[indexPath.row]
        let resolved = self.resolveRow(row, presentationData: presentationData)
        
        cell.backgroundColor = presentationData.theme.chatList.backgroundColor
        cell.textLabel?.text = resolved.title
        cell.textLabel?.textColor = presentationData.theme.list.itemPrimaryTextColor
        cell.detailTextLabel?.text = resolved.subtitle
        cell.detailTextLabel?.textColor = presentationData.theme.list.itemSecondaryTextColor
        
        cell.accessibilityLabel = resolved.accessibilityLabel
        cell.accessibilityHint = resolved.hint
        cell.accessibilityTraits = resolved.traits
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard indexPath.row >= 0, indexPath.row < self.rows.count else {
            return
        }
        let row = self.rows[indexPath.row]
        switch row.entry {
        case .HeaderEntry:
            self.actions.activateSearch?()
        default:
            self.actions.openEntry?(row.entry)
        }
    }
}
