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

import Combine
import Foundation
import InputBarAccessoryView
import UIKit

/// A subclass of `UIViewController` with a `MessagesCollectionView` object
/// that is used to display conversation interfaces.
open class MessagesViewController: UIViewController, UICollectionViewDelegateFlowLayout, MessagesCollectionViewFlowLayoutDelegate {
    
  // MARK: Lifecycle

  deinit {
      NotificationCenter.default.removeObserver(self, name: UIMenuController.willShowMenuNotification, object: nil)
      MessageStyle.bubbleImageCache.removeAllObjects()
  }

  // MARK: Open

  /// The `MessagesCollectionView` managed by the messages view controller object.
  open var messagesCollectionView = MessagesCollectionView()

  /// The `InputBarAccessoryView` used as the `inputAccessoryView` in the view controller.
  open lazy var messageInputBar = InputBarAccessoryView()

  /// Display the date of message by swiping left.
  /// The default value of this property is `false`.
  open var showMessageTimestampOnSwipeLeft = false {
    didSet {
      messagesCollectionView.showMessageTimestampOnSwipeLeft = showMessageTimestampOnSwipeLeft
      if showMessageTimestampOnSwipeLeft {
        addPanGesture()
      } else {
        removePanGesture()
      }
    }
  }

  /// A CGFloat value that adds to (or, if negative, subtracts from) the automatically
  /// computed value of `messagesCollectionView.contentInset.bottom`. Meant to be used
  /// as a measure of last resort when the built-in algorithm does not produce the right
  /// value for your app. Please let us know when you end up having to use this property.
  open var additionalBottomInset: CGFloat = 0 {
    didSet {
      updateMessageCollectionViewBottomInset()
    }
  }

  /// withAdditionalBottomSpace parameter for InputBarAccessoryView's KeyboardManager
  open func inputBarAdditionalBottomSpace() -> CGFloat {
    0
  }

  open override func viewDidLoad() {
    super.viewDidLoad()
    setupDefaults()
    setupSubviews()
    setupConstraints()
    setupInputBar(for: inputBarType)
    setupDelegates()
    addObservers()
    addKeyboardObservers()
    /// Layout input container view and update messagesCollectionViewInsets
    view.layoutIfNeeded()
    messagesCollectionView.transform = .init(scaleX: 1, y: -1)
    messagesCollectionView.contentInsetAdjustmentBehavior = .never
    messagesCollectionView.automaticallyAdjustsScrollIndicatorInsets = false
    diffableDataSource = .init(collectionView: messagesCollectionView) { collectionView, indexPath, entry in
      guard let messagesCollectionView = collectionView as? MessagesCollectionView else {
        fatalError(MessageKitError.notMessagesCollectionView)
      }
     guard let messagesDataSource = messagesCollectionView.messagesDataSource else {
        fatalError(MessageKitError.nilMessagesDataSource)
      }

      switch entry.kind {
      case .message(let message):
        switch message.kind {
        case .text, .attributedText, .emoji:
          if let cell = messagesDataSource.textCell(for: message, at: indexPath, in: messagesCollectionView) {
            return cell
          } else {
            let cell = messagesCollectionView.dequeueReusableCell(TextMessageCell.self, for: indexPath)
            cell.configure(with: message, at: indexPath, and: messagesCollectionView)
            return cell
          }
        case .photo, .video:
          if let cell = messagesDataSource.photoCell(for: message, at: indexPath, in: messagesCollectionView) {
            return cell
          } else {
            let cell = messagesCollectionView.dequeueReusableCell(MediaMessageCell.self, for: indexPath)
            cell.configure(with: message, at: indexPath, and: messagesCollectionView)
            return cell
          }
        case .location:
          if let cell = messagesDataSource.locationCell(for: message, at: indexPath, in: messagesCollectionView) {
            return cell
          } else {
            let cell = messagesCollectionView.dequeueReusableCell(LocationMessageCell.self, for: indexPath)
            cell.configure(with: message, at: indexPath, and: messagesCollectionView)
            return cell
          }
        case .audio:
          if let cell = messagesDataSource.audioCell(for: message, at: indexPath, in: messagesCollectionView) {
            return cell
          } else {
            let cell = messagesCollectionView.dequeueReusableCell(AudioMessageCell.self, for: indexPath)
            cell.configure(with: message, at: indexPath, and: messagesCollectionView)
            return cell
          }
        case .contact:
          if let cell = messagesDataSource.contactCell(for: message, at: indexPath, in: messagesCollectionView) {
            return cell
          } else {
            let cell = messagesCollectionView.dequeueReusableCell(ContactMessageCell.self, for: indexPath)
            cell.configure(with: message, at: indexPath, and: messagesCollectionView)
            return cell
          }
        case .linkPreview:
          let cell = messagesCollectionView.dequeueReusableCell(LinkPreviewMessageCell.self, for: indexPath)
          cell.configure(with: message, at: indexPath, and: messagesCollectionView)
          return cell
        case .custom:
          return messagesDataSource.customCell(for: message, at: indexPath, in: messagesCollectionView)
        }
      case .typingIndicator:
          return messagesDataSource.typingIndicator(at: indexPath, in: messagesCollectionView)
      }
    }

    diffableDataSource?.supplementaryViewProvider = { collectionView, kind, indexPath in
      guard let messagesCollectionView = collectionView as? MessagesCollectionView else {
        fatalError(MessageKitError.notMessagesCollectionView)
      }
      guard let displayDelegate = messagesCollectionView.messagesDisplayDelegate else {
        fatalError(MessageKitError.nilMessagesDisplayDelegate)
      }
      switch kind {
      case UICollectionView.elementKindSectionHeader:
        return displayDelegate.messageHeaderView(for: indexPath, in: messagesCollectionView)
      case UICollectionView.elementKindSectionFooter:
        return displayDelegate.messageFooterView(for: indexPath, in: messagesCollectionView)
      default:
        fatalError(MessageKitError.unrecognizedSectionKind)
      }
    }
  }

  open override func viewSafeAreaInsetsDidChange() {
    super.viewSafeAreaInsetsDidChange()
    updateMessageCollectionViewBottomInset()

    messagesCollectionView.verticalScrollIndicatorInsets.bottom = view.safeAreaInsets.top
    messagesCollectionView.contentInset.bottom = view.safeAreaInsets.top
  }

  public func updateDataSource(
      animated: Bool,
      completion: @escaping (() -> Void) = {}
  ) {
    guard let messagesDataSource = messagesCollectionView.messagesDataSource else {
      fatalError(MessageKitError.nilMessagesDataSource)
    }
    guard let diffableDataSource else {
      fatalError("Update called before data source was initialized")
    }
    var snapshot = NSDiffableDataSourceSnapshot<Int, Entry>()

    let sections = messagesDataSource.numberOfSections(in: messagesCollectionView)

    let internalCompletion = {
        completion()
    }

    for section in 0..<sections {
      snapshot.appendSections([section])
      let items = messagesDataSource.numberOfItems(inSection: section, in: messagesCollectionView)
      for item in 0..<items {
        let indexPath = IndexPath(item: item, section: section)
        let message = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView)
        snapshot.appendItems([.init(kind: .message(message))], toSection: section)
      }
    }

    if !isTypingIndicatorHidden {
      snapshot.appendSections([sections])
      snapshot.appendItems([.init(kind: .typingIndicator)])
    }

    var oldSnapshot = diffableDataSource.snapshot()
    let oldItems = Set(oldSnapshot.itemIdentifiers)
    let newItems = Set(snapshot.itemIdentifiers)

    let unchangedItems = oldItems.intersection(newItems)
    let addedItems = newItems.subtracting(oldItems)
    let removedItems = oldItems.subtracting(newItems)

    // We have new items added or removed so we do a full reload
    if !addedItems.isEmpty || !removedItems.isEmpty {
      diffableDataSource.apply(snapshot, animatingDifferences: animated, completion: internalCompletion)
    } else if !unchangedItems.isEmpty {
      if #available(iOS 15.0, *) {
        for oldItem in oldItems {
          if let item = newItems.first(where: { $0.hashValue == oldItem.hashValue }) {
            switch (item.kind, oldItem.kind) {
              case (.message(let message), .message(let oldMessage)):
                if message.hash != oldMessage.hash {
                    oldSnapshot.reloadItems([oldItem])
                }
              default:
                oldSnapshot.reloadItems([oldItem])
            }
          } else {
              oldSnapshot.reloadItems([oldItem])
          }
        }
        diffableDataSource.apply(oldSnapshot, animatingDifferences: animated, completion: internalCompletion)
      } else {
        diffableDataSource.apply(snapshot, animatingDifferences: animated, completion: internalCompletion)
      }
    } else {
      // There were no changes at all, so we just call completion
      completion()
    }
  }

  // MARK: - UICollectionViewDelegateFlowLayout

  open func collectionView(
    _: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath)
    -> CGSize
  {
    guard let messagesFlowLayout = collectionViewLayout as? MessagesCollectionViewFlowLayout else { return .zero }
    return messagesFlowLayout.sizeForItem(at: indexPath)
  }

  open func collectionView(
    _ collectionView: UICollectionView,
    layout _: UICollectionViewLayout,
    referenceSizeForHeaderInSection section: Int)
    -> CGSize
  {
    guard let messagesCollectionView = collectionView as? MessagesCollectionView else {
      fatalError(MessageKitError.notMessagesCollectionView)
    }
    guard let layoutDelegate = messagesCollectionView.messagesLayoutDelegate else {
      fatalError(MessageKitError.nilMessagesLayoutDelegate)
    }
    if isSectionReservedForTypingIndicator(section) {
      return .zero
    }
    return layoutDelegate.headerViewSize(for: section, in: messagesCollectionView)
  }

  open func collectionView(_: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    switch diffableDataSource?.itemIdentifier(for: indexPath)?.kind {
    case .none, .typingIndicator:
      break
    case .message(let message):
      messagesCollectionView.messagesDisplayDelegate?.willDisplayCell(
        for: message,
        at: indexPath,
        in: messagesCollectionView)
    }
    guard let cell = cell as? TypingIndicatorCell else { return }
    cell.typingBubble.startAnimating()
  }

  open func collectionView(
    _ collectionView: UICollectionView,
    layout _: UICollectionViewLayout,
    referenceSizeForFooterInSection section: Int)
    -> CGSize
  {
    guard let messagesCollectionView = collectionView as? MessagesCollectionView else {
      fatalError(MessageKitError.notMessagesCollectionView)
    }
    guard let layoutDelegate = messagesCollectionView.messagesLayoutDelegate else {
      fatalError(MessageKitError.nilMessagesLayoutDelegate)
    }
    if isSectionReservedForTypingIndicator(section) {
      return .zero
    }
    return layoutDelegate.footerViewSize(for: section, in: messagesCollectionView)
  }

  open func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemsAt indexPaths: [IndexPath], point: CGPoint) ->  UIContextMenuConfiguration? {
    guard let messagesDataSource = messagesCollectionView.messagesDataSource else {
      fatalError(MessageKitError.nilMessagesDataSource)
    }
    guard let indexPath = indexPaths.first else { return nil }
    let pasteBoard = UIPasteboard.general
    let message = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView)

    enum Content {
      case text(String)
      case image(UIImage)
    }

    let content: Content?

    switch message.kind {
    case .text(let text), .emoji(let text):
      content = .text(text)
    case .attributedText(let attributedText):
      content = .text(attributedText.string)
    case .photo(let mediaItem):
      content = .image(mediaItem.image ?? mediaItem.placeholderImage)
    default:
      content = nil
    }
    if let content {
      return UIContextMenuConfiguration(previewProvider: nil) { action in
        let copy = UIAction(title: "Copy") { _ in
            switch content {
            case .image(let image):
                pasteBoard.image = image
            case .text(let text):
                pasteBoard.string = text
            }
        }
        return UIMenu(options: UIMenu.Options.displayInline, children: [copy])
      }
    } else {
      return nil
    }
  }

  open func collectionView(_ collectionView: UICollectionView, contextMenuConfiguration configuration: UIContextMenuConfiguration, highlightPreviewForItemAt indexPath: IndexPath) -> UITargetedPreview? {
    targetedPreview(forItemAt: indexPath)
  }

  open func collectionView(_ collectionView: UICollectionView, contextMenuConfiguration configuration: UIContextMenuConfiguration, dismissalPreviewForItemAt indexPath: IndexPath) -> UITargetedPreview? {
    targetedPreview(forItemAt: indexPath)
  }

  func messagesCollectionViewFlowLayout(_ layout: MessagesCollectionViewFlowLayout, isSectionReservedForTypingIndicator section: Int) -> Bool {
      isSectionReservedForTypingIndicator(section)
  }

  // MARK: Public

  public var selectedIndexPathForMenu: IndexPath?

  // MARK: Internal

  // MARK: - Internal properties

  internal let state: State = .init()
  internal var isTypingIndicatorHidden: Bool = true

  // MARK: Private

  // MARK: - Private methods

  private var diffableDataSource: UICollectionViewDiffableDataSource<Int, Entry>?

  func isSectionReservedForTypingIndicator(_ section: Int) -> Bool {
    guard let diffableDataSource else {
      fatalError("Data source is not initialized")
    }
    return diffableDataSource
      .snapshot()
      .itemIdentifiers(inSection: section)
      .contains(where: {
        switch $0.kind {
        case .message:
          return false
        case .typingIndicator:
          return true
        }
      })
  }

  private func setupDefaults() {
    extendedLayoutIncludesOpaqueBars = true
    view.backgroundColor = .collectionViewBackground
    messagesCollectionView.keyboardDismissMode = .interactive
    messagesCollectionView.alwaysBounceVertical = true
    messagesCollectionView.backgroundColor = .collectionViewBackground
  }

  private func setupSubviews() {
    view.addSubviews(messagesCollectionView, inputContainerView)
  }

  private func setupConstraints() {
    messagesCollectionView.translatesAutoresizingMaskIntoConstraints = false
    /// Constraints of inputContainerView are managed by keyboardManager
    inputContainerView.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      messagesCollectionView.topAnchor.constraint(equalTo: view.topAnchor),
      messagesCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      messagesCollectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
      messagesCollectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
    ])
  }

  private func setupDelegates() {
    messagesCollectionView.delegate = self
  }

  private func setupInputBar(for kind: MessageInputBarKind) {
    inputContainerView.subviews.forEach { $0.removeFromSuperview() }

    func pinViewToInputContainer(_ view: UIView) {
      view.translatesAutoresizingMaskIntoConstraints = false
      inputContainerView.addSubviews(view)

      NSLayoutConstraint.activate([
        view.topAnchor.constraint(equalTo: inputContainerView.topAnchor),
        view.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor),
        view.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor),
        view.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor),
      ])
    }

    switch kind {
    case .messageInputBar:
      pinViewToInputContainer(messageInputBar)
    case .custom(let view):
      pinViewToInputContainer(view)
    }
  }

  private func addObservers() {
    NotificationCenter.default
      .publisher(for: UIApplication.didReceiveMemoryWarningNotification)
      .subscribe(on: DispatchQueue.global())
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        self?.clearMemoryCache()
      }
      .store(in: &disposeBag)

    state.$inputBarType
      .subscribe(on: DispatchQueue.global())
      .dropFirst()
      .removeDuplicates()
      .receive(on: DispatchQueue.main)
      .sink(receiveValue: { [weak self] newType in
        self?.setupInputBar(for: newType)
      })
      .store(in: &disposeBag)
  }

  private func clearMemoryCache() {
    MessageStyle.bubbleImageCache.removeAllObjects()
  }

  func targetedPreview(forItemAt indexPath: IndexPath) -> UITargetedPreview? {
    guard let cell = messagesCollectionView.cellForItem(at: indexPath) as? MessageContentCell else { return nil }
    let parameters = UIPreviewParameters()
    parameters.backgroundColor = .clear
    // TODO: We need to set the chat bubble path here

    return .init(view: cell.messageContainerView, parameters: parameters)
  }
}

internal struct Entry: Hashable, @unchecked Sendable {
  enum Kind {
    case message(MessageType)
    case typingIndicator
  }

  let kind: Kind

  func hash(into hasher: inout Hasher) {
    // We explicitly don't hash the message content hash here since at this level we want to know about position
    // changes, not content changes
    switch kind {
    case .message(let message):
      hasher.combine(message.messageId)
    case .typingIndicator:
      hasher.combine("typingIndicator")
    }
  }

  static func == (lhs: Entry, rhs: Entry) -> Bool {
    switch (lhs.kind, rhs.kind) {
    case (.message(let lhs), .message(let rhs)):
      return lhs.messageId == rhs.messageId
    case (.typingIndicator, .typingIndicator):
      return true
    default:
      return false
    }
  }
}
