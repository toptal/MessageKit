// MIT License
//
// Copyright (c) 2017-2025 MessageKit
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

import UIKit

public class SystemMessageSizeCalculator: CellSizeCalculator {

  private let messageContainerPadding: UIEdgeInsets = .init(top: 8, left: 16, bottom: 8, right: 16)

  // MARK: Lifecycle

  public init(layout: MessagesCollectionViewFlowLayout? = nil) {
    super.init()
    self.layout = layout
  }

  override public func sizeForItem(at indexPath: IndexPath) -> CGSize {
    let dataSource = messagesLayout.messagesDataSource
    let message = dataSource.messageForItem(at: indexPath, in: messagesLayout.messagesCollectionView)
    let itemHeight = messageContainerSize(for: message).height + messageContainerPadding.vertical
    return CGSize(width: messagesLayout.itemWidth, height: itemHeight)
  }

  override public func configure(attributes: UICollectionViewLayoutAttributes) {
    guard let attributes = attributes as? MessagesCollectionViewLayoutAttributes else { return }

    let dataSource = messagesLayout.messagesDataSource
    let message = dataSource.messageForItem(at: attributes.indexPath, in: messagesLayout.messagesCollectionView)
    attributes.messageContainerSize = messageContainerSize(for: message)
    attributes.messageContainerPadding = messageContainerPadding
  }

  func messageContainerSize(for message: MessageType) -> CGSize {
    let attributedText: NSAttributedString
    switch message.kind {
    case .system(let text):
      attributedText = text
    default:
      fatalError("messageContainerSize received unhandled MessageDataType: \(message.kind)")
    }

    let maxWidth = messagesLayout.itemWidth - messageContainerPadding.horizontal
    var labelSize = labelSize(for: attributedText, considering: maxWidth)
    labelSize.width = messagesLayout.itemWidth
    return labelSize
  }

  public var messagesLayout: MessagesCollectionViewFlowLayout {
    guard let layout = layout as? MessagesCollectionViewFlowLayout else {
      fatalError("Layout object is missing or is not a MessagesCollectionViewFlowLayout")
    }
    return layout
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
