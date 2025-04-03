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

extension MessagesViewController {
  // MARK: Internal

  // MARK: - Register Observers

  internal func addKeyboardObservers() {
    keyboardManager.bind(
      inputAccessoryView: inputContainerView, 
      withAdditionalBottomSpace: { [weak self] in self?.inputBarAdditionalBottomSpace() ?? 0 }
    )
    keyboardManager.bind(to: messagesCollectionView)

    /// Observe didBeginEditing to scroll content to last item if necessary
    NotificationCenter.default
      .publisher(for: UITextView.textDidBeginEditingNotification)
      /// Wait for inputBar frame change animation to end
      .delay(for: .milliseconds(200), scheduler: DispatchQueue.main)
      .sink { [weak self] notification in
        self?.handleTextViewDidBeginEditing(notification)
      }
      .store(in: &disposeBag)

    NotificationCenter.default
      .publisher(for: UITextView.textDidChangeNotification)
      .compactMap { $0.object as? InputTextView }
      .filter { [weak self] textView in
        textView == self?.messageInputBar.inputTextView
      }
      .map(\.text)
      .removeDuplicates()
      .sink { [weak self] _ in
        if !(self?.maintainPositionOnInputBarHeightChanged ?? false) {
          // Get the right frame of input bar - we need this for correct scrollToLastItem animation
          self?.view.setNeedsLayout()
          self?.view.layoutIfNeeded()
          self?.messagesCollectionView.scrollToLastItem(animated: false)
        }
      }
      .store(in: &disposeBag)

    NotificationCenter.default
      .publisher(for: UITextInputMode.currentInputModeDidChangeNotification)
      .removeDuplicates()
      .sink { [weak self] _ in
        if !(self?.maintainPositionOnInputBarHeightChanged ?? false) {
          // Get the right frame of input bar - we need this for correct scrollToLastItem animation
          self?.view.setNeedsLayout()
          self?.view.layoutIfNeeded()
          self?.messagesCollectionView.scrollToLastItem(animated: false)
        }
      }
      .store(in: &disposeBag)

      state.insetKeyboardManager.on(event: .willShow) { [weak self] notification in
        self?.updateInsets(from: notification)
      }
      state.insetKeyboardManager.on(event: .willChangeFrame) { [weak self] notification in
        self?.updateInsets(from: notification)
      }
      state.insetKeyboardManager.on(event: .willHide) { [weak self] notification in
        self?.updateInsets(from: notification)
      }

      // There is no need to observe the frame here - InputAccessoryView will trigger a layout pass that in turn
      // will correctly recalculate the inset.
      state.$keyboardInset
        .removeDuplicates()
        .combineLatest(
          state.$additionalBottomInset.removeDuplicates()
        )
        .sink(receiveValue: { [weak self] _, _ in
            self?.recalculateInsets()
        })
        .store(in: &state.disposeBag)
  }

  // MARK: - Updating insets

  private func updateInsets(from notification: KeyboardNotification) {
    guard let parent = messagesCollectionView.superview, let window = parent.window else { return }
    // Grab end frame in window coordinates
    let collectionViewFrameInScrollParentCoordinates = parent.convert(messagesCollectionView.frame, to: window)
    let parentRect = collectionViewFrameInScrollParentCoordinates.intersection(notification.endFrame)

    let finalInset = parentRect.height

    UIView.animate(
      withDuration: notification.timeInterval,
      delay: 0,
      options: notification.animationOptions,
      animations: { [state] in
        state.keyboardInset = finalInset
      }
    )
  }

  func recalculateInsets() {
    guard let collectionParent = messagesCollectionView.superview else { return }
    let inset = state.keyboardInset
    let additionalInset = state.additionalBottomInset

    let convertedInputBarFrame = collectionParent.convert(inputContainerView.bounds, from: inputContainerView)
    // We make a strong assumption here that the input bar frame is in the same coordinate space as collection view
    let inputBarOverlappingHeight = convertedInputBarFrame.intersection(messagesCollectionView.frame).height

    let finalInset = inset + inputBarOverlappingHeight + additionalInset
    messagesCollectionView.contentInset.top = finalInset
    messagesCollectionView.verticalScrollIndicatorInsets.top = inset + inputBarOverlappingHeight
  }

  // MARK: Private

  /// UIScrollView can automatically add safe area insets to its contentInset,
  /// which needs to be accounted for when setting the contentInset based on screen coordinates.
  /// Note: We have the collection view flipped so we're using top instead of bottom here
  ///
  /// - Returns: The distance automatically added to contentInset.bottom, if any.
  private var automaticallyAddedBottomInset: CGFloat {
    messagesCollectionView.adjustedContentInset.top - messageCollectionViewBottomInset
  }

  private var messageCollectionViewBottomInset: CGFloat {
    messagesCollectionView.contentInset.top
  }

  // MARK: - Private methods

  private func handleTextViewDidBeginEditing(_ notification: Notification) {
    guard
      scrollsToLastItemOnKeyboardBeginsEditing,
      let inputTextView = notification.object as? InputTextView,
      inputTextView === messageInputBar.inputTextView
    else {
      return
    }
    messagesCollectionView.scrollToLastItem()
  }
}
