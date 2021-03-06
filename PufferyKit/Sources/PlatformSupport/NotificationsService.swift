//
//  NoitifcationsService.swift
//  Puffery
//
//  Created by Valentin Knabel on 18.06.20.
//  Copyright © 2020 Valentin Knabel. All rights reserved.
//

import APIDefinition
import UserNotifications

@objc public class NotificationsService: NSObject, UNUserNotificationCenterDelegate {
    public func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        defer {
            DispatchQueue.main.async(execute: Widgets.reloadAll)
        }
        if let subscribedChannel = ReceivedMessageNotification(content: response.notification.request.content) {
            NotificationCenter.default.post(name: .receivedMessage, object: nil, userInfo: [
                "ReceivedMessageNotification": subscribedChannel,
            ])
            completionHandler()
        } else {
            completionHandler()
        }
    }
}

public extension ReceivedMessageNotification {
    convenience init?(content: UNNotificationContent) {
        if let channelUUIDString = content.userInfo["subscribedChannelID"] as? String,
            let channelID = UUID(uuidString: channelUUIDString),
            let messageUUIDString = content.userInfo["receivedMessageID"] as? String,
            let messageID = UUID(uuidString: messageUUIDString)
        {
            self.init(messageID: messageID, channelID: channelID)
        } else {
            return nil
        }
    }
}
