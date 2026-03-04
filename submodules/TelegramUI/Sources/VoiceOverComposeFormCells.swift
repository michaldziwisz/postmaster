import Foundation
import UIKit

final class VoiceOverFormTextFieldCell: UITableViewCell, UITextFieldDelegate {
    let textField = UITextField()
    
    var maxLength: Int?
    var onTextChanged: ((String) -> Void)?
    var onReturn: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.selectionStyle = .none
        self.isAccessibilityElement = false
        
        self.textField.translatesAutoresizingMaskIntoConstraints = false
        self.textField.clearButtonMode = .whileEditing
        self.textField.delegate = self
        self.contentView.addSubview(self.textField)
        
        NSLayoutConstraint.activate([
            self.textField.leadingAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.leadingAnchor),
            self.textField.trailingAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.trailingAnchor),
            self.textField.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 10.0),
            self.textField.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -10.0)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.textField.removeTarget(nil, action: nil, for: .editingChanged)
        self.onTextChanged = nil
        self.onReturn = nil
        self.maxLength = nil
    }
    
    func configure(
        text: String,
        placeholder: String?,
        accessibilityLabel: String?,
        isEnabled: Bool,
        returnKeyType: UIReturnKeyType,
        keyboardType: UIKeyboardType = .default,
        autocapitalizationType: UITextAutocapitalizationType = .sentences
    ) {
        self.textField.text = text
        self.textField.placeholder = placeholder
        self.textField.accessibilityLabel = accessibilityLabel ?? placeholder
        self.textField.isEnabled = isEnabled
        self.textField.returnKeyType = returnKeyType
        self.textField.keyboardType = keyboardType
        self.textField.autocapitalizationType = autocapitalizationType
        self.textField.addTarget(self, action: #selector(self.editingChanged), for: .editingChanged)
    }
    
    @objc private func editingChanged() {
        self.onTextChanged?(self.textField.text ?? "")
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let maxLength else {
            return true
        }
        let current = textField.text ?? ""
        guard let range = Range(range, in: current) else {
            return true
        }
        let updated = current.replacingCharacters(in: range, with: string)
        return updated.count <= maxLength
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.onReturn?()
        return false
    }
}

