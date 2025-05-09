// MIT License
//
// Copyright (c) 2017-2022 MessageKit
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation
import UIKit

// MARK: - MessageSizeCalculator

open class MessageSizeCalculator: CellSizeCalculator {
  // MARK: Lifecycle

  public init(layout: MessagesCollectionViewFlowLayout? = nil) {
    super.init()

    self.layout = layout
  }

  // MARK: Open

  open override func configure(attributes: UICollectionViewLayoutAttributes) {
    guard let attributes = attributes as? MessagesCollectionViewLayoutAttributes else { return }

    let dataSource = messagesLayout.messagesDataSource
    let indexPath = attributes.indexPath
    let message = dataSource.messageForItem(at: indexPath, in: messagesLayout.messagesCollectionView)

    attributes.avatarSize = avatarSize(for: message, at: indexPath)
    attributes.avatarPosition = avatarPosition(for: message)
    attributes.avatarLeadingTrailingPadding = avatarLeadingTrailingPadding

    attributes.messageContainerPadding = messageContainerPadding(for: message)
    attributes.messageContainerSize = messageContainerSizeWithAttachments(for: message, at: indexPath)
    attributes.cellTopLabelSize = cellTopLabelSize(for: message, at: indexPath)
    attributes.cellTopLabelAlignment = cellTopLabelAlignment(for: message)
    attributes.cellBottomLabelSize = cellBottomLabelSize(for: message, at: indexPath)
    attributes.messageTimeLabelSize = messageTimeLabelSize(for: message, at: indexPath)
    attributes.cellBottomLabelAlignment = cellBottomLabelAlignment(for: message)
    attributes.messageTopLabelSize = messageTopLabelSize(for: message, at: indexPath)
    attributes.messageTopLabelAlignment = messageTopLabelAlignment(for: message, at: indexPath)

    attributes.messageBottomLabelAlignment = messageBottomLabelAlignment(for: message, at: indexPath)
    attributes.messageBottomLabelSize = messageBottomLabelSize(for: message, at: indexPath)

    attributes.accessoryViewSize = accessoryViewSize(for: message, at: indexPath)
    attributes.accessoryViewPadding = accessoryViewPadding(for: message)
    attributes.accessoryViewPosition = accessoryViewPosition(for: message)

    attributes.attachmentSize = attachmentViewSize(for: message, at: indexPath)
    attributes.attachmentPadding = attachmentPadding(for: message, at: indexPath)
  }

  open override func sizeForItem(at indexPath: IndexPath) -> CGSize {
    let dataSource = messagesLayout.messagesDataSource
    let message = dataSource.messageForItem(at: indexPath, in: messagesLayout.messagesCollectionView)
    let itemHeight = cellContentHeight(for: message, at: indexPath)
    return CGSize(width: messagesLayout.itemWidth, height: itemHeight)
  }

  open func cellContentHeight(for message: MessageType, at indexPath: IndexPath) -> CGFloat {
    let messageContainerHeight = messageContainerSizeWithAttachments(for: message, at: indexPath).height
    let cellBottomLabelHeight = cellBottomLabelSize(for: message, at: indexPath).height
    let messageBottomLabelHeight = messageBottomLabelSize(for: message, at: indexPath).height
    let cellTopLabelHeight = cellTopLabelSize(for: message, at: indexPath).height
    let messageTopLabelHeight = messageTopLabelSize(for: message, at: indexPath).height
    let messageVerticalPadding = messageContainerPadding(for: message).vertical
    let avatarHeight = avatarSize(for: message, at: indexPath).height
    let avatarVerticalPosition = avatarPosition(for: message).vertical
    let accessoryViewHeight = accessoryViewSize(for: message, at: indexPath).height

    switch avatarVerticalPosition {
    case .messageCenter:
      let totalLabelHeight: CGFloat = cellTopLabelHeight + messageTopLabelHeight
        + messageContainerHeight + messageVerticalPadding + messageBottomLabelHeight + cellBottomLabelHeight
      let cellHeight = max(avatarHeight, totalLabelHeight)
      return max(cellHeight, accessoryViewHeight)
    case .messageBottom:
      var cellHeight: CGFloat = 0
      cellHeight += messageBottomLabelHeight
      cellHeight += cellBottomLabelHeight
      let labelsHeight = messageContainerHeight + messageVerticalPadding + cellTopLabelHeight + messageTopLabelHeight
      cellHeight += max(labelsHeight, avatarHeight)
      return max(cellHeight, accessoryViewHeight)
    case .messageTop:
      var cellHeight: CGFloat = 0
      cellHeight += cellTopLabelHeight
      cellHeight += messageTopLabelHeight
      let labelsHeight = messageContainerHeight + messageVerticalPadding + messageBottomLabelHeight + cellBottomLabelHeight
      cellHeight += max(labelsHeight, avatarHeight)
      return max(cellHeight, accessoryViewHeight)
    case .messageLabelTop:
      var cellHeight: CGFloat = 0
      cellHeight += cellTopLabelHeight
      let messageLabelsHeight = messageContainerHeight + messageBottomLabelHeight + messageVerticalPadding +
        messageTopLabelHeight + cellBottomLabelHeight
      cellHeight += max(messageLabelsHeight, avatarHeight)
      return max(cellHeight, accessoryViewHeight)
    case .cellTop, .cellBottom:
      let totalLabelHeight: CGFloat = cellTopLabelHeight + messageTopLabelHeight
        + messageContainerHeight + messageVerticalPadding + messageBottomLabelHeight + cellBottomLabelHeight
      let cellHeight = max(avatarHeight, totalLabelHeight)
      return max(cellHeight, accessoryViewHeight)
    }
  }

  // MARK: - Avatar

  open func avatarPosition(for message: MessageType) -> AvatarPosition {
    let dataSource = messagesLayout.messagesDataSource
    let isFromCurrentSender = dataSource.isFromCurrentSender(message: message)
    var position = isFromCurrentSender ? outgoingAvatarPosition : incomingAvatarPosition

    switch position.horizontal {
    case .cellTrailing, .cellLeading:
      break
    case .natural:
      position.horizontal = isFromCurrentSender ? .cellTrailing : .cellLeading
    }
    return position
  }

  open func avatarSize(for message: MessageType, at indexPath: IndexPath) -> CGSize {
    let layoutDelegate = messagesLayout.messagesLayoutDelegate
    let collectionView = messagesLayout.messagesCollectionView
    if let size = layoutDelegate.avatarSize(for: message, at: indexPath, in: collectionView) {
      return size
    }
    let dataSource = messagesLayout.messagesDataSource
    let isFromCurrentSender = dataSource.isFromCurrentSender(message: message)
    return isFromCurrentSender ? outgoingAvatarSize : incomingAvatarSize
  }

  // MARK: - Top cell Label

  open func cellTopLabelSize(for message: MessageType, at indexPath: IndexPath) -> CGSize {
    let layoutDelegate = messagesLayout.messagesLayoutDelegate
    let collectionView = messagesLayout.messagesCollectionView
    let height = layoutDelegate.cellTopLabelHeight(for: message, at: indexPath, in: collectionView)
    return CGSize(width: messagesLayout.itemWidth, height: height)
  }

  open func cellTopLabelAlignment(for message: MessageType) -> LabelAlignment {
    let dataSource = messagesLayout.messagesDataSource
    let isFromCurrentSender = dataSource.isFromCurrentSender(message: message)
    return isFromCurrentSender ? outgoingCellTopLabelAlignment : incomingCellTopLabelAlignment
  }

  // MARK: - Top message Label

  open func messageTopLabelSize(for message: MessageType, at indexPath: IndexPath) -> CGSize {
    let layoutDelegate = messagesLayout.messagesLayoutDelegate
    let collectionView = messagesLayout.messagesCollectionView
    let height = layoutDelegate.messageTopLabelHeight(for: message, at: indexPath, in: collectionView)
    return CGSize(width: messagesLayout.itemWidth, height: height)
  }

  open func messageTopLabelAlignment(for message: MessageType, at indexPath: IndexPath) -> LabelAlignment {
    let collectionView = messagesLayout.messagesCollectionView
    let layoutDelegate = messagesLayout.messagesLayoutDelegate

    if let alignment = layoutDelegate.messageTopLabelAlignment(for: message, at: indexPath, in: collectionView) {
      return alignment
    }

    let dataSource = messagesLayout.messagesDataSource
    let isFromCurrentSender = dataSource.isFromCurrentSender(message: message)
    return isFromCurrentSender ? outgoingMessageTopLabelAlignment : incomingMessageTopLabelAlignment
  }

  // MARK: - Message time label

  open func messageTimeLabelSize(for message: MessageType, at indexPath: IndexPath) -> CGSize {
    let dataSource = messagesLayout.messagesDataSource
    guard let attributedText = dataSource.messageTimestampLabelAttributedText(for: message, at: indexPath) else {
      return .zero
    }
    let size = attributedText.size()
    return CGSize(width: size.width, height: size.height)
  }

  // MARK: - Bottom cell Label

  open func cellBottomLabelSize(for message: MessageType, at indexPath: IndexPath) -> CGSize {
    let layoutDelegate = messagesLayout.messagesLayoutDelegate
    let collectionView = messagesLayout.messagesCollectionView
    let height = layoutDelegate.cellBottomLabelHeight(for: message, at: indexPath, in: collectionView)
    return CGSize(width: messagesLayout.itemWidth, height: height)
  }

  open func cellBottomLabelAlignment(for message: MessageType) -> LabelAlignment {
    let dataSource = messagesLayout.messagesDataSource
    let isFromCurrentSender = dataSource.isFromCurrentSender(message: message)
    return isFromCurrentSender ? outgoingCellBottomLabelAlignment : incomingCellBottomLabelAlignment
  }

  // MARK: - Bottom Message Label

  open func messageBottomLabelSize(for message: MessageType, at indexPath: IndexPath) -> CGSize {
    let layoutDelegate = messagesLayout.messagesLayoutDelegate
    let collectionView = messagesLayout.messagesCollectionView
    let height = layoutDelegate.messageBottomLabelHeight(for: message, at: indexPath, in: collectionView)
    return CGSize(width: messagesLayout.itemWidth, height: height)
  }

  open func messageBottomLabelAlignment(for message: MessageType, at indexPath: IndexPath) -> LabelAlignment {
    let collectionView = messagesLayout.messagesCollectionView
    let layoutDelegate = messagesLayout.messagesLayoutDelegate

    if let alignment = layoutDelegate.messageBottomLabelAlignment(for: message, at: indexPath, in: collectionView) {
      return alignment
    }

    let dataSource = messagesLayout.messagesDataSource
    let isFromCurrentSender = dataSource.isFromCurrentSender(message: message)
    return isFromCurrentSender ? outgoingMessageBottomLabelAlignment : incomingMessageBottomLabelAlignment
  }

  // MARK: - MessageContainer

  open func messageContainerPadding(for message: MessageType) -> UIEdgeInsets {
    let dataSource = messagesLayout.messagesDataSource
    let isFromCurrentSender = dataSource.isFromCurrentSender(message: message)
    return isFromCurrentSender ? outgoingMessagePadding : incomingMessagePadding
  }

    open func messageContainerSize(for _: MessageType, at _: IndexPath) -> CGSize {
      // Returns .zero by default
      .zero
    }

  open func messageContainerSizeWithAttachments(for message: MessageType, at indexPath: IndexPath) -> CGSize {
    let attachmentSize = attachmentViewSize(for: message, at: indexPath)
    let attachmentPadding = attachmentPadding(for: message, at: indexPath)
    var baseSize = messageContainerSize(for: message, at: indexPath)
    guard attachmentSize != .zero else {
      return baseSize
    }

    baseSize.width = messageContainerMaxWidth(for: message, at: indexPath)
    baseSize.height += attachmentSize.height + attachmentPadding.vertical

    return baseSize
  }

  open func messageContainerMaxWidth(for message: MessageType, at indexPath: IndexPath) -> CGFloat {
    let avatarWidth: CGFloat = avatarSize(for: message, at: indexPath).width
    let messagePadding = messageContainerPadding(for: message)
    let accessoryWidth = accessoryViewSize(for: message, at: indexPath).width
    let accessoryPadding = accessoryViewPadding(for: message)
    return messagesLayout.itemWidth - avatarWidth - messagePadding.horizontal - accessoryWidth - accessoryPadding
      .horizontal - avatarLeadingTrailingPadding
  }

  // MARK: Attachments

  open func attachmentPadding(for message: MessageType, at indexPath: IndexPath) -> UIEdgeInsets {
    let dataSource = messagesLayout.messagesDataSource
    let isFromCurrentSender = dataSource.isFromCurrentSender(message: message)
    return isFromCurrentSender ? outgoingAttachmentViewPadding : incomingAttachmentViewPadding
  }

  // MARK: Public

  public var incomingAvatarSize = CGSize(width: 30, height: 30)
  public var outgoingAvatarSize = CGSize(width: 30, height: 30)

  public var incomingAvatarPosition = AvatarPosition(vertical: .cellBottom)
  public var outgoingAvatarPosition = AvatarPosition(vertical: .cellBottom)

  public var avatarLeadingTrailingPadding: CGFloat = 0

  public var incomingMessagePadding = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 30)
  public var outgoingMessagePadding = UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 4)

  public var incomingCellTopLabelAlignment = LabelAlignment(textAlignment: .center, textInsets: .zero)
  public var outgoingCellTopLabelAlignment = LabelAlignment(textAlignment: .center, textInsets: .zero)

  public var incomingCellBottomLabelAlignment = LabelAlignment(textAlignment: .left, textInsets: UIEdgeInsets(left: 42))
  public var outgoingCellBottomLabelAlignment = LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(right: 42))

  public var incomingMessageTopLabelAlignment = LabelAlignment(textAlignment: .left, textInsets: UIEdgeInsets(left: 42))
  public var outgoingMessageTopLabelAlignment = LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(right: 42))

  public var incomingMessageBottomLabelAlignment = LabelAlignment(textAlignment: .left, textInsets: UIEdgeInsets(left: 42))
  public var outgoingMessageBottomLabelAlignment = LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(right: 42))

  public var incomingAccessoryViewSize = CGSize.zero
  public var outgoingAccessoryViewSize = CGSize.zero

  public var incomingAccessoryViewPadding = HorizontalEdgeInsets.zero
  public var outgoingAccessoryViewPadding = HorizontalEdgeInsets.zero

  public var incomingAccessoryViewPosition: AccessoryPosition = .messageCenter
  public var outgoingAccessoryViewPosition: AccessoryPosition = .messageCenter

  public var incomingAttachmentViewPadding = UIEdgeInsets(top: 0, left: 18, bottom: 7, right: 14)
  public var outgoingAttachmentViewPadding = UIEdgeInsets(top: 0, left: 14, bottom: 7, right: 18)

  // MARK: - Helpers

  public var messagesLayout: MessagesCollectionViewFlowLayout {
    guard let layout = layout as? MessagesCollectionViewFlowLayout else {
      fatalError("Layout object is missing or is not a MessagesCollectionViewFlowLayout")
    }
    return layout
  }

  // MARK: - Accessory View

  public func accessoryViewSize(for message: MessageType, at indexPath: IndexPath) -> CGSize {
    let collectionView = messagesLayout.messagesCollectionView
    let layoutDelegate = messagesLayout.messagesLayoutDelegate

    if let size = layoutDelegate.accessorySize(for: message, at: indexPath, in: collectionView) {
      return size
    }

    let dataSource = messagesLayout.messagesDataSource
    let isFromCurrentSender = dataSource.isFromCurrentSender(message: message)
    return isFromCurrentSender ? outgoingAccessoryViewSize : incomingAccessoryViewSize
  }

  public func attachmentViewSize(for message: MessageType, at indexPath: IndexPath) -> CGSize {
    let collectionView = messagesLayout.messagesCollectionView
    let layoutDelegate = messagesLayout.messagesLayoutDelegate
    let padding = attachmentPadding(for: message, at: indexPath)
    let maxWidth = messageContainerMaxWidth(for: message, at: indexPath) - padding.horizontal
    if let height = layoutDelegate.attachmentHeight(for: message, at: indexPath, maxWidth: maxWidth, in: collectionView) {
        return .init(width: maxWidth, height: height)
    }

    return .zero
  }

  public func accessoryViewPadding(for message: MessageType) -> HorizontalEdgeInsets {
    let dataSource = messagesLayout.messagesDataSource
    let isFromCurrentSender = dataSource.isFromCurrentSender(message: message)
    return isFromCurrentSender ? outgoingAccessoryViewPadding : incomingAccessoryViewPadding
  }

  public func accessoryViewPosition(for message: MessageType) -> AccessoryPosition {
    let dataSource = messagesLayout.messagesDataSource
    let isFromCurrentSender = dataSource.isFromCurrentSender(message: message)
    return isFromCurrentSender ? outgoingAccessoryViewPosition : incomingAccessoryViewPosition
  }

  // MARK: Internal
  internal lazy var textContainer: NSTextContainer = {
    let textContainer = NSTextContainer()
    textContainer.maximumNumberOfLines = 0
    textContainer.lineFragmentPadding = 0
    return textContainer
  }()
  internal lazy var layoutManager: NSLayoutManager = {
    let layoutManager = NSLayoutManager()
    layoutManager.addTextContainer(textContainer)
    return layoutManager
  }()
  internal lazy var textStorage: NSTextStorage = {
    let textStorage = NSTextStorage()
    textStorage.addLayoutManager(layoutManager)
    return textStorage
  }()

  internal func labelSize(for attributedText: NSAttributedString, considering maxWidth: CGFloat) -> CGSize {
    let constraintBox = CGSize(width: maxWidth, height: .greatestFiniteMagnitude)

    textContainer.size = constraintBox
    textStorage.replaceCharacters(in: NSRange(location: 0, length: textStorage.length), with: attributedText)
    layoutManager.ensureLayout(for: textContainer)

    let size = layoutManager.usedRect(for: textContainer).size

    return CGSize(width: size.width.rounded(.up), height: size.height.rounded(.up))
  }
}

extension UIEdgeInsets {
  fileprivate init(top: CGFloat = 0, bottom: CGFloat = 0, left: CGFloat = 0, right: CGFloat = 0) {
    self.init(top: top, left: left, bottom: bottom, right: right)
  }
}
