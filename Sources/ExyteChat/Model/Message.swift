//
//  Message.swift
//  Chat
//
//  Created by Alisa Mylnikova on 20.04.2022.
//

import SwiftUI

public struct Message: Identifiable, Hashable {

    public struct ToolInfo: Hashable, Equatable {

        public init(
            toolId: String,
            status: Status,
            onAccept: @escaping () -> Void,
            onDecline: @escaping () -> Void
        ) {
            self.toolId = toolId
            self.status = status
            self.onAccept = onAccept
            self.onDecline = onDecline
        }

        public enum Status {
            case waitingForConfirmation
            case confirmed
            case declined
        }

        public let toolId: String
        public let status: Status
        public let onAccept: () -> Void
        public let onDecline: () -> Void

        public func hash(into hasher: inout Hasher) {
            hasher.combine(toolId)
            hasher.combine(status)
        }

        public static func == (lhs: ToolInfo, rhs: ToolInfo) -> Bool {
            lhs.toolId == rhs.toolId && lhs.status == rhs.status
        }
    }

    public enum Status: Equatable, Hashable {
        case sending
        case sent
        case read
        case error(DraftMessage)

        public func hash(into hasher: inout Hasher) {
            switch self {
            case .sending:
                return hasher.combine("sending")
            case .sent:
                return hasher.combine("sent")
            case .read:
                return hasher.combine("read")
            case .error:
                return hasher.combine("error")
            }
        }

        public static func == (lhs: Message.Status, rhs: Message.Status) -> Bool {
            switch (lhs, rhs) {
            case (.sending, .sending):
                return true
            case (.sent, .sent):
                return true
            case (.read, .read):
                return true
            case ( .error(_), .error(_)):
                return true
            default:
                return false
            }
        }
    }

    public var id: String
    public var user: User
    public var status: Status?
    public var createdAt: Date

    public var text: String
    public var attachments: [Attachment]
    public var recording: Recording?
    public var replyMessage: ReplyMessage?
    public var toolInfo: ToolInfo?

    public init(id: String,
                user: User,
                status: Status? = nil,
                createdAt: Date = Date(),
                text: String = "",
                attachments: [Attachment] = [],
                recording: Recording? = nil,
                replyMessage: ReplyMessage? = nil,
                toolInfo: ToolInfo? = nil) {
        self.id = id
        self.user = user
        self.status = status
        self.createdAt = createdAt
        self.text = text
        self.attachments = attachments
        self.recording = recording
        self.replyMessage = replyMessage
        self.toolInfo = toolInfo
    }

    public static func makeMessage(
        id: String,
        user: User,
        status: Status? = nil,
        draft: DraftMessage) async -> Message {
            let attachments = await draft.medias.asyncCompactMap { media -> Attachment? in
                guard let thumbnailURL = await media.getThumbnailURL() else {
                    return nil
                }

                switch media.type {
                case .image:
                    return Attachment(id: UUID().uuidString, url: thumbnailURL, type: .image)
                case .video:
                    guard let fullURL = await media.getURL() else {
                        return nil
                    }
                    return Attachment(id: UUID().uuidString, thumbnail: thumbnailURL, full: fullURL, type: .video)
                }
            }

            return Message(id: id, user: user, status: status, createdAt: draft.createdAt, text: draft.text, attachments: attachments, recording: draft.recording, replyMessage: draft.replyMessage)
        }
}

extension Message {
    var time: String {
        DateFormatter.timeFormatter.string(from: createdAt)
    }
}

extension Message: Equatable {
    public static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id && lhs.status == rhs.status && lhs.toolInfo == rhs.toolInfo
    }
}

public struct Recording: Codable, Hashable {
    public var duration: Double
    public var waveformSamples: [CGFloat]
    public var url: URL?

    public init(duration: Double = 0.0, waveformSamples: [CGFloat] = [], url: URL? = nil) {
        self.duration = duration
        self.waveformSamples = waveformSamples
        self.url = url
    }
}

public struct ReplyMessage: Codable, Identifiable, Hashable {
    public static func == (lhs: ReplyMessage, rhs: ReplyMessage) -> Bool {
        lhs.id == rhs.id
    }

    public var id: String
    public var user: User

    public var text: String
    public var attachments: [Attachment]
    public var recording: Recording?

    public init(id: String,
                user: User,
                text: String = "",
                attachments: [Attachment] = [],
                recording: Recording? = nil) {

        self.id = id
        self.user = user
        self.text = text
        self.attachments = attachments
        self.recording = recording
    }

    func toMessage() -> Message {
        Message(id: id, user: user, text: text, attachments: attachments, recording: recording)
    }
}

public extension Message {

    func toReplyMessage() -> ReplyMessage {
        ReplyMessage(id: id, user: user, text: text, attachments: attachments, recording: recording)
    }
}
