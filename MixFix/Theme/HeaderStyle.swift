import SwiftUI

enum MFHeaderStyle {
    static func unifiedHeaderGradient(
        moodColorsEnabled: Bool,
        hasRecentMood: Bool,
        latestMood: Int?,
        profileCircleColorName: String
    ) -> LinearGradient {
        let profileGradient: LinearGradient = {
            switch profileCircleColorName {
            case "sage": return LinearGradient(colors: [Color(hex: "#8AB86D"), Color(hex: "#2D4A1A")], startPoint: .topLeading, endPoint: .bottomTrailing)
            case "terracotta": return LinearGradient(colors: [Color(hex: "#D97358"), Color(hex: "#5A1810")], startPoint: .topLeading, endPoint: .bottomTrailing)
            case "sand": return LinearGradient(colors: [Color(hex: "#D9C28F"), Color(hex: "#6B4A2D")], startPoint: .topLeading, endPoint: .bottomTrailing)
            case "clay": return LinearGradient(colors: [Color(hex: "#A0855C"), Color(hex: "#3A2010")], startPoint: .topLeading, endPoint: .bottomTrailing)
            case "moss": return LinearGradient(colors: [Color(hex: "#7F9C4C"), Color(hex: "#1F2A0A")], startPoint: .topLeading, endPoint: .bottomTrailing)
            case "stone": return LinearGradient(colors: [Color(hex: "#8F8F8F"), Color(hex: "#2A2A2A")], startPoint: .topLeading, endPoint: .bottomTrailing)
            case "olive": return LinearGradient(colors: [Color(hex: "#9A9766"), Color(hex: "#3A3A18")], startPoint: .topLeading, endPoint: .bottomTrailing)
            case "cream": return LinearGradient(colors: [Color(hex: "#DCC6A5"), Color(hex: "#7A5A30")], startPoint: .topLeading, endPoint: .bottomTrailing)
            case "slate": return LinearGradient(colors: [Color(hex: "#697E8D"), Color(hex: "#1A2530")], startPoint: .topLeading, endPoint: .bottomTrailing)
            case "taupe": return LinearGradient(colors: [Color(hex: "#AD8564"), Color(hex: "#4A2815")], startPoint: .topLeading, endPoint: .bottomTrailing)
            case "lavender": return LinearGradient(colors: [Color(hex: "#AA95C8"), Color(hex: "#4A3060")], startPoint: .topLeading, endPoint: .bottomTrailing)
            case "periwinkle": return LinearGradient(colors: [Color(hex: "#8E9CD0"), Color(hex: "#2A3560")], startPoint: .topLeading, endPoint: .bottomTrailing)
            case "amethyst": return LinearGradient(colors: [Color(hex: "#9568A8"), Color(hex: "#2D1040")], startPoint: .topLeading, endPoint: .bottomTrailing)
            case "sky": return LinearGradient(colors: [Color(hex: "#7BBCD4"), Color(hex: "#1A4A68")], startPoint: .topLeading, endPoint: .bottomTrailing)
            case "ocean": return LinearGradient(colors: [Color(hex: "#7DB8E8"), Color(hex: "#2A5A98")], startPoint: .topLeading, endPoint: .bottomTrailing)
            case "indigo": return LinearGradient(colors: [Color(hex: "#8B9FEB"), Color(hex: "#2A3F85")], startPoint: .topLeading, endPoint: .bottomTrailing)
            case "rose": return LinearGradient(colors: [Color(hex: "#FFC8D8"), Color(hex: "#D8537F")], startPoint: .topLeading, endPoint: .bottomTrailing)
            case "blush": return LinearGradient(colors: [Color(hex: "#FFD8E1"), Color(hex: "#FF6F83")], startPoint: .topLeading, endPoint: .bottomTrailing)
            case "coral": return LinearGradient(colors: [Color(hex: "#FFB8A0"), Color(hex: "#FF4F41")], startPoint: .topLeading, endPoint: .bottomTrailing)
            case "peach": return LinearGradient(colors: [Color(hex: "#FFCBB1"), Color(hex: "#FF6A45")], startPoint: .topLeading, endPoint: .bottomTrailing)
            case "tangerine": return LinearGradient(colors: [Color(hex: "#FFD76D"), Color(hex: "#FF7800")], startPoint: .topLeading, endPoint: .bottomTrailing)
            case "crimson": return LinearGradient(colors: [Color(hex: "#FF9393"), Color(hex: "#B31F1F")], startPoint: .topLeading, endPoint: .bottomTrailing)
            case "ruby": return LinearGradient(colors: [Color(hex: "#FF7370"), Color(hex: "#A61818")], startPoint: .topLeading, endPoint: .bottomTrailing)
            case "mint": return LinearGradient(colors: [Color(hex: "#98D8C8"), Color(hex: "#2E8B7A")], startPoint: .topLeading, endPoint: .bottomTrailing)
            case "burgundy": return LinearGradient(colors: [Color(hex: "#B8697D"), Color(hex: "#6B2737")], startPoint: .topLeading, endPoint: .bottomTrailing)
            default:
                return LinearGradient(colors: [Color(hex: "#8AB86D"), Color(hex: "#2D4A1A")], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }()

        let moodGradient: LinearGradient = {
            guard let mood = latestMood else {
                return profileGradient
            }
            switch mood {
            case 9: return LinearGradient(colors: [Color(hex: "#B565D8"), Color(hex: "#5E35B1")], startPoint: .topLeading, endPoint: .bottomTrailing)
            case 8: return LinearGradient(colors: [Color(hex: "#FFE66D"), Color(hex: "#F39C12")], startPoint: .topLeading, endPoint: .bottomTrailing)
            case 7: return LinearGradient(colors: [Color(hex: "#7BA8D9"), Color(hex: "#4A7AB8")], startPoint: .topLeading, endPoint: .bottomTrailing)
            case 6: return LinearGradient(colors: [Color(hex: "#FFA726"), Color(hex: "#E53935")], startPoint: .topLeading, endPoint: .bottomTrailing)
            case 5: return LinearGradient(colors: [Color(hex: "#8FB86D"), Color(hex: "#4A7A2F")], startPoint: .topLeading, endPoint: .bottomTrailing)
            case 4: return LinearGradient(colors: [Color(hex: "#A1887F"), Color(hex: "#3E2723")], startPoint: .topLeading, endPoint: .bottomTrailing)
            case 3: return LinearGradient(colors: [Color(hex: "#7E7E9A"), Color(hex: "#2E2E3F")], startPoint: .topLeading, endPoint: .bottomTrailing)
            case 2: return LinearGradient(colors: [Color(hex: "#3949AB"), Color(hex: "#0D1B3E")], startPoint: .topLeading, endPoint: .bottomTrailing)
            case 1: return LinearGradient(colors: [Color(hex: "#C62828"), Color(hex: "#4A0000")], startPoint: .topLeading, endPoint: .bottomTrailing)
            default:
                return profileGradient
            }
        }()

        if moodColorsEnabled && hasRecentMood && latestMood != nil {
            return moodGradient
        } else {
            return profileGradient
        }
    }
}
