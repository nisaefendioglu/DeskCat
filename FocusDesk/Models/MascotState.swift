import Foundation

enum MascotMood: String, CaseIterable, Identifiable {
    case focusing
    case slowing
    case drowsy
    case sleeping

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .focusing: "mood.focusing"
        case .slowing: "mood.slowing"
        case .drowsy: "mood.drowsy"
        case .sleeping: "mood.sleeping"
        }
    }

    @MainActor
    var title: String {
        LanguageStore.shared.t(titleKey)
    }
}
