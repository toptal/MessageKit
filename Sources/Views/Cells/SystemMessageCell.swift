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

/// A subclass of `MessageCollectionViewCell` used to display a system message.
open class SystemMessageCell: MessageCollectionViewCell {
  private let systemMessageLabel = UILabel()

  public override init(frame: CGRect) {
    super.init(frame: frame)
    contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    setupSubviews()
  }

  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    setupSubviews()
  }

  open override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
    super.apply(layoutAttributes)
    guard let attributes = layoutAttributes as? MessagesCollectionViewLayoutAttributes else { return }

    var systemMessageFrame = CGRect.zero
    systemMessageFrame.size = attributes.messageContainerSize
    systemMessageFrame.origin = .init(
      x: attributes.messageLabelInsets.left,
      y: attributes.messageLabelInsets.left
    )

    systemMessageLabel.frame = systemMessageFrame.integral
  }

  func configure(
    with message: NSAttributedString,
    at indexPath: IndexPath,
    and messagesCollectionView: MessagesCollectionView)
  {
    systemMessageLabel.attributedText = message
  }
}

private extension SystemMessageCell {
  func setupSubviews() {
    addSubview(systemMessageLabel)
  }    
}
