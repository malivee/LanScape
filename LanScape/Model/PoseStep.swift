import Foundation

/// Represents a single pose movement step in a dance sequence.
public struct PoseStep: Identifiable, Equatable {
    public let id: Int
    public let title: String
    public let descriptionText: String
    public let upImageName: String
    public let downImageName: String

    public init(
        id: Int,
        title: String,
        descriptionText: String,
        upImageName: String,
        downImageName: String
    ) {
        self.id = id
        self.title = title
        self.descriptionText = descriptionText
        self.upImageName = upImageName
        self.downImageName = downImageName
    }
}

extension PoseStep {
    /// The default 4-step dance sequence matching DancePose2 Core ML classes in order: 2, 1, 3, 4.
    public static let sampleSequence: [PoseStep] = [
        PoseStep(
            id: 2,
            title: "Gerakan 1",
            descriptionText: "Rentangkan tangan sesuai panduan gerakan",
            upImageName: "2up",
            downImageName: "2down"
        ),
        PoseStep(
            id: 1,
            title: "Gerakan 2",
            descriptionText: "Angkat tangan dan ikuti pose tubuh bagian atas",
            upImageName: "1up",
            downImageName: "1down"
        ),
        PoseStep(
            id: 3,
            title: "Gerakan 3",
            descriptionText: "Posisikan tubuh sesuai siluet gerakan ketiga",
            upImageName: "3up",
            downImageName: "3down"
        ),
        PoseStep(
            id: 4,
            title: "Gerakan 4",
            descriptionText: "Kunci pose terakhir untuk menyelesaikan sesi",
            upImageName: "4up",
            downImageName: "4down"
        )
    ]
}
