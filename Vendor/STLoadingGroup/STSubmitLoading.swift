//
//  STSubmitLoading.swift
//  STCycleLoadView-SubmitButton
//
//  Created by TangJR on 1/4/16.
//  Copyright © 2016. All rights reserved.
//

/*
 The MIT License (MIT)

 Copyright (c) 2016 saitjr

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import UIKit

typealias STEmptyCallback = () -> ()

protocol STLoadingable {
    var isLoading: Bool { get }

    func startLoading()
    func stopLoading(finish: STEmptyCallback?)
}

protocol STLoadingConfig {
    var animationDuration: TimeInterval { get }
    var lineWidth: CGFloat { get }
    var loadingTintColor: UIColor { get }
}

class STSubmitLoading: UIView
{
    fileprivate let cycleLayer: CAShapeLayer = CAShapeLayer()

    internal var isLoading: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        updateUI()
    }
}

extension STSubmitLoading {
    fileprivate func setupUI() {
        cycleLayer.lineCap = kCALineCapRound
        cycleLayer.lineJoin = kCALineJoinRound
        cycleLayer.lineWidth = lineWidth
        cycleLayer.fillColor = UIColor.clear.cgColor
        cycleLayer.strokeColor = loadingTintColor.cgColor
        cycleLayer.strokeEnd = 0

        layer.addSublayer(cycleLayer)
    }

    fileprivate func updateUI() {
        cycleLayer.bounds = bounds
        cycleLayer.position = CGPoint(x: bounds.width / 2.0, y: bounds.height / 2.0)
        cycleLayer.path = UIBezierPath(ovalIn: bounds).cgPath
    }
}

extension STSubmitLoading: STLoadingConfig {
    var animationDuration: TimeInterval {
        return 1
    }

    var lineWidth: CGFloat {
        return 3
    }

    var loadingTintColor: UIColor {
        return UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)
    }
}

extension STSubmitLoading: STLoadingable {
    fileprivate func drawCrossDash() -> CAShapeLayer {
        let dash = CAShapeLayer()
        dash.frame = CGRect(x: 0.0, y: 0.0, width: 44.0, height: 44.0)
        dash.lineCap = kCALineCapRound
        dash.lineJoin = kCALineJoinRound
        dash.fillColor = nil
        dash.strokeColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0).cgColor
        dash.lineWidth = 3
        dash.fillMode = kCAFillModeForwards
        
        return dash
    }

    internal func startLoading() {
        guard !isLoading else {
            return
        }
        isLoading = true

        self.alpha = 1

        let strokeEndAnimation = CABasicAnimation(keyPath: "strokeEnd")
        strokeEndAnimation.fromValue = 0
        strokeEndAnimation.toValue = 0.75
        strokeEndAnimation.fillMode = kCAFillModeForwards
        strokeEndAnimation.isRemovedOnCompletion = false
        strokeEndAnimation.duration = animationDuration / 3.0
        cycleLayer.add(strokeEndAnimation, forKey: "strokeEndAnimation")

        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.fromValue = 0
        rotateAnimation.toValue = Double.pi * 2
        rotateAnimation.duration = animationDuration
        rotateAnimation.beginTime = CACurrentMediaTime() + strokeEndAnimation.duration
        rotateAnimation.repeatCount = Float.infinity
        cycleLayer.add(rotateAnimation, forKey: "rotateAnimation")
    }

    internal func stopLoading(finish: STEmptyCallback? = nil) {
        guard isLoading else {
            return
        }

        let strokeEndAnimation = CABasicAnimation(keyPath: "strokeEnd")
        strokeEndAnimation.toValue = 1
        strokeEndAnimation.fillMode = kCAFillModeForwards
        strokeEndAnimation.isRemovedOnCompletion = false
        strokeEndAnimation.duration = animationDuration * 3.0 / 4.0
        cycleLayer.add(strokeEndAnimation, forKey: "catchStrokeEndAnimation")

        UIView.animate(withDuration: 0.3, delay: strokeEndAnimation.duration, options: UIViewAnimationOptions(), animations: { () -> Void in
            self.alpha = 0
        }, completion: { _ in
            self.cycleLayer.removeAllAnimations()
            self.isLoading = false
            finish?()
        })
    }
}

extension STSubmitLoading {
    func show(_ inView: UIView?, offset: CGPoint = .zero, autoHide: TimeInterval = 0) {
        if self.superview != nil {
            self.removeFromSuperview()
        }
        var showInView = UIApplication.shared.keyWindow ?? UIView()
        if let inView = inView {
            showInView = inView
        }
        let showInViewSize = showInView.frame.size
        self.center = CGPoint(x: showInViewSize.width * 0.5, y: showInViewSize.height * 0.5)
        showInView.addSubview(self)
    }

    func remove() {
        if self.superview != nil {
            stopLoading() {
                self.removeFromSuperview()
            }
        }
    }

    func showCancelCross() {
        let dash1 = drawCrossDash()
        dash1.path = {
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 12.0, y: 12.0))
            path.addLine(to: CGPoint(x: 25.0, y: 25.0))
            return path.cgPath
        }()

        let dash2 = drawCrossDash()
        dash2.path = {
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 25.0, y: 12.0))
            path.addLine(to: CGPoint(x: 12.0, y: 25.0))
            return path.cgPath
        }()

        let view = UIView(frame: CGRect(x: 0, y: 0, width: 48, height: 48))
        view.layer.addSublayer(dash1)
        view.layer.addSublayer(dash2)
        view.alpha = 0

        self.addSubview(view)

        UIView.animate(withDuration: 0.2, animations: {
            view.alpha = 1
        })
    }
}
