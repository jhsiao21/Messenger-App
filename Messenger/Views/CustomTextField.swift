import Foundation
import UIKit

class CustomTextField: UITextField {
    
    var textEdited: ((String) -> Void)? = nil
    
    func textValidation(completion: @escaping (String) -> Void) {
        textEdited = completion
        addTarget(self,
                  action: #selector(textFieldEditingChanged(_ :)),
                  for: .editingChanged)
        
    }
    
    @objc func textFieldEditingChanged(_ textField: UITextField) {
        guard let text = textField.text else { return }
        textEdited?(text)
        
    }
}
