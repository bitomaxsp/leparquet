import Foundation

public enum Errors: Error {
    case validationFailed(String)
    case inputConfigUnsupported(String)
}
