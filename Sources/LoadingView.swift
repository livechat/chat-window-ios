//
//  LoadingView.swift
//  Pods
//
//  Created by Łukasz Jerciński on 31/03/2017.
//
//

import Foundation
import UIKit

protocol LoadingViewDelegate : NSObjectProtocol {
    func reload()
    func close()
}

fileprivate let darkGrey = UIColor(red: 90.0 / 255.0, green: 105.0 / 255.0, blue: 118.0 / 255.0, alpha: 1.0)

class LoadingView : UIView {
    private let activityIndicator = ActivityIndicator()
    private let closeButton = CloseButton()
    private let errorView = ErrorView()
    weak var delegate : LoadingViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        
        backgroundColor = UIColor.white
        
        errorView.reloadButton.addTarget(self, action: #selector(reload), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        closeButton.alpha = 0
        
        addSubview(activityIndicator)
        addSubview(closeButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        activityIndicator.sizeToFit()
        activityIndicator.center = CGPoint(x: bounds.midX, y: bounds.midY - 20)
        
        let size = errorView.sizeThatFits(CGSize(width: bounds.size.width - 40, height: bounds.size.height - 100))
        errorView.frame = CGRect(x: 20, y: 0, width: size.width, height: size.height)
        errorView.center = CGPoint(x: bounds.midX, y: bounds.midY - 20)
        
        closeButton.sizeToFit()
        closeButton.frame = CGRect(x: bounds.size.width - 44 - 10, y: 10, width: 44, height: 44)
    }
    
    func startAnimation() {
        activityIndicator.startAnimation()
        addSubview(activityIndicator)
        errorView.removeFromSuperview()
        closeButton.alpha = 0
        
        UIView.animate(withDuration: 0.3, delay: 3.0, options: [], animations: {
            self.closeButton.alpha = 1.0
        }, completion: nil)
        
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    func stopAnimation() {
        activityIndicator.stopAnimation()
    }

    func displayLoadingError(withMessage message: String) {
        errorView.message = message
        addSubview(errorView)
        activityIndicator.removeFromSuperview()
        closeButton.alpha = 1.0
        stopAnimation()
        
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    @objc func reload() {
        startAnimation()
        delegate?.reload()
    }
    
    @objc func close() {
        delegate?.close()
    }
}

private class CloseButton : UIButton {
    private let closeIcon = CAShapeLayer()
    private let closeIconPath : UIBezierPath
    let baseSize : CGFloat = 14.0
    
    init() {
        closeIconPath = UIBezierPath()
        
        super.init(frame: CGRect.zero)
        
        closeIconPath.move(to: CGPoint(x: 14, y: 1.41))
        closeIconPath.addLine(to: CGPoint(x: 12.59, y: 0))
        closeIconPath.addLine(to: CGPoint(x: 7, y: 5.59))
        closeIconPath.addLine(to: CGPoint(x: 1.41, y: 0))
        closeIconPath.addLine(to: CGPoint(x: 0, y: 1.41))
        closeIconPath.addLine(to: CGPoint(x: 5.59, y: 7))
        closeIconPath.addLine(to: CGPoint(x: 0, y: 12.59))
        closeIconPath.addLine(to: CGPoint(x: 1.41, y: 14))
        closeIconPath.addLine(to: CGPoint(x: 7, y: 8.41))
        closeIconPath.addLine(to: CGPoint(x: 12.59, y: 14))
        closeIconPath.addLine(to: CGPoint(x: 14, y: 12.59))
        closeIconPath.addLine(to: CGPoint(x: 8.41, y: 7))
        closeIconPath.addLine(to: CGPoint(x: 14, y: 1.41))
        closeIconPath.close()
        closeIconPath.usesEvenOddFillRule = true
        
        closeIcon.path = closeIconPath.cgPath
        
        closeIcon.fillColor = UIColor.black.cgColor
        
        layer.addSublayer(closeIcon)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                closeIcon.fillColor = UIColor.black.withAlphaComponent(0.5).cgColor
            } else {
                closeIcon.fillColor = UIColor.black.cgColor
            }
        }
    }
    
    override func sizeToFit() {
        super.sizeToFit()
        bounds = CGRect(x: 0, y: 0, width: 44, height: 44)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let width = bounds.size.width
        let height = bounds.size.height
        
        closeIcon.frame = CGRect(x: (width - baseSize) / 2.0, y: (height - baseSize) / 2.0, width: baseSize, height: baseSize)
    }
    
    private func applyScaled(bezier: UIBezierPath, scalingFactor: CGFloat, toLayer layer: CAShapeLayer) {
        let scalingTransform = CGAffineTransform(scaleX: scalingFactor, y: scalingFactor)
        
        let dPatch = UIBezierPath(cgPath: bezier.cgPath)
        dPatch.apply(scalingTransform)
        layer.path = dPatch.cgPath
    }
}

private class ErrorView : UIView {
    fileprivate let reloadButton = ReloadButton()
    private let label = UILabel()
    fileprivate var message = "" {
        didSet {
            label.text = message
            
            setNeedsLayout()
            layoutIfNeeded()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        
        label.numberOfLines = 0
        label.textColor = UIColor.black
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16.0)
        label.text = ""
        addSubview(label)
        
        addSubview(reloadButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let size = label.sizeThatFits(CGSize(width: bounds.size.width, height: bounds.size.height))
        label.frame = CGRect(x: (bounds.size.width - size.width) / 2.0, y: 0, width: size.width, height: size.height)
        
        reloadButton.sizeToFit()
        reloadButton.frame = CGRect(x: (bounds.size.width - reloadButton.bounds.size.width) / 2.0, y: label.frame.maxY + 44, width: reloadButton.bounds.size.width, height: reloadButton.bounds.size.height)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let size = label.sizeThatFits(CGSize(width: size.width, height: size.height))
        
        reloadButton.sizeToFit()
        
        return CGSize(width: max(size.width, reloadButton.bounds.size.width), height: size.height + 44 + reloadButton.bounds.size.height)
    }
}

private class ReloadButton : UIButton {
    init() {
        super.init(frame: CGRect.zero)
        
        setTitle("Reload", for: UIControl.State())
        setTitleColor(darkGrey, for: UIControl.State())
        setTitleColor(UIColor.white, for: .highlighted)
        
        layer.cornerRadius = 6
        layer.borderWidth = 1
        layer.borderColor = darkGrey.cgColor
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                layer.backgroundColor = darkGrey.withAlphaComponent(0.5).cgColor
            } else {
                layer.backgroundColor = UIColor.white.cgColor
            }
        }
    }
    
    override func sizeToFit() {
        super.sizeToFit()
        
        bounds = bounds.insetBy(dx: -14, dy: -6)
    }
}

public extension UIImage {
    convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}

private class ActivityIndicator : UIView {
    private let activityIndicator = ActivityIndicatorLayer()
    private let label = UILabel()
    private var animating = false
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        
        backgroundColor = UIColor.white
        layer.addSublayer(activityIndicator)
        
        label.numberOfLines = 0
        label.textColor = darkGrey
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16.0)
        label.text = "Loading..."
        addSubview(label)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        activityIndicator.frame = CGRect(x: floor((bounds.width - 60) / 2.0), y: 0, width: 60, height: 60)
        
        label.sizeToFit()
        label.frame = CGRect(x: floor((bounds.width - label.frame.size.width) / 2.0), y: activityIndicator.frame.maxY + 10, width: label.frame.size.width, height: label.frame.size.height)
    }
    
    override func sizeToFit() {
        label.sizeToFit()
        
        bounds = CGRect(x: 0, y: 0, width: max(60, label.frame.size.width), height: 60 + 10 + label.frame.size.height)
    }
    
    func startAnimation() {
        
        let oldAnimation = activityIndicator.animation(forKey: "rotationAnimation")
        
        if oldAnimation == nil {
            animating = true
            
            let animation = CABasicAnimation(keyPath: "transform.rotation")
            animation.duration = 1
            animation.toValue = Float(Float.pi * 2.0)
            animation.isCumulative = true
            animation.repeatCount = Float.greatestFiniteMagnitude
            
            activityIndicator.add(animation, forKey: "rotationAnimation")
            
            NotificationCenter.default.removeObserver(self)
            NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        }
    }
    
    func stopAnimation() {
        animating = false
        
        NotificationCenter.default.removeObserver(self)
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if animating {
            startAnimation()
        }
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if animating {
            startAnimation()
        }
    }
    
    @objc func applicationDidBecomeActive() {
        if animating {
            startAnimation()
        }
    }
}

private class ActivityIndicatorLayer : CALayer {
    
    // MARK: Properties
    
    static let baseSize = 60.0
    let darkCircleLayer = CAShapeLayer()
    var darkGreyCirclePath = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: baseSize, height: baseSize))
    var outMaskingCirclePath = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: baseSize, height: baseSize))
    var maskingCirclePath = UIBezierPath(ovalIn: CGRect(x: 6, y: 6, width: baseSize - 12, height: baseSize - 12))
    
    let lightCircleLayer = CAShapeLayer()
    var lightGrayCirclePath : UIBezierPath
    let maskingLayer = CAShapeLayer()
    let outMaskingLayer = CAShapeLayer()

    // MARK: Initializers
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(layer: Any) {
        lightGrayCirclePath = ActivityIndicatorLayer.makelightGrayCirclePath(CGFloat(ActivityIndicatorLayer.baseSize))
        super.init(layer: layer)
    }

    override init() {
        lightGrayCirclePath = ActivityIndicatorLayer.makelightGrayCirclePath(CGFloat(ActivityIndicatorLayer.baseSize))
        
        super.init()
        self.setupLayers()
        self.setupLayersHierarchy()
    }
    
    // MARK: Setup methods
    
    func setupLayers() {
        self.setupDarkCircleLayer()
        self.setupLightCircleLayer()
        self.setupOutMaskingLayer()
        self.setupMaskingLayer()
    }
    
    func setupDarkCircleLayer() {
        darkCircleLayer.path = darkGreyCirclePath.cgPath
        darkCircleLayer.fillColor = UIColor(red: 0.392, green: 0.439, blue: 0.498, alpha: 1.000).cgColor
    }
    
    func setupLightCircleLayer() {
        lightCircleLayer.path = lightGrayCirclePath.cgPath
        lightCircleLayer.fillColor = UIColor(red: 0.824, green: 0.855, blue: 0.890, alpha: 1.000).cgColor
    }
    
    func setupOutMaskingLayer() {
        outMaskingLayer.path = outMaskingCirclePath.cgPath
        outMaskingLayer.fillColor = UIColor.clear.cgColor
        outMaskingLayer.strokeColor = UIColor.white.withAlphaComponent(1.0).cgColor
        outMaskingLayer.lineWidth = 1
    }
    
    func setupMaskingLayer() {
        maskingLayer.path = maskingCirclePath.cgPath
        maskingLayer.fillColor = UIColor.white.cgColor
    }
    
    func setupLayersHierarchy() {
        addSublayer(darkCircleLayer)
        addSublayer(lightCircleLayer)
        addSublayer(maskingLayer)
        addSublayer(outMaskingLayer)
    }
    
    static func makelightGrayCirclePath(_ baseSize: CGFloat) -> UIBezierPath {
        let lightGrayCircleRect = CGRect(x: 0, y: 0, width: baseSize, height: baseSize)
        let path = UIBezierPath()

        path.addArc(
            withCenter: CGPoint(x: lightGrayCircleRect.midX, y: lightGrayCircleRect.midY),
            radius: lightGrayCircleRect.width / 2,
            startAngle: -45 * CGFloat.pi/180,
            endAngle: -135 * CGFloat.pi/180,
            clockwise: true
        )
        path.addLine(to: CGPoint(x: lightGrayCircleRect.midX, y: lightGrayCircleRect.midY))
        path.close()

        return path
    }
    
    // MARK: Lifecycle methods

    override func layoutSublayers() {
        super.layoutSublayers()

        darkCircleLayer.frame = bounds
        lightCircleLayer.frame = bounds
        maskingLayer.frame = bounds
        outMaskingLayer.frame = bounds

        let scalingFactor = bounds.size.width / CGFloat(ActivityIndicatorLayer.baseSize)

        applyScaled(bezier: darkGreyCirclePath, scalingFactor: scalingFactor, toLayer: darkCircleLayer)
        applyScaled(bezier: lightGrayCirclePath, scalingFactor: scalingFactor, toLayer: lightCircleLayer)
        applyScaled(bezier: maskingCirclePath, scalingFactor: scalingFactor, toLayer: maskingLayer)
        applyScaled(bezier: outMaskingCirclePath, scalingFactor: scalingFactor, toLayer: outMaskingLayer)
    }
    
    private func applyScaled(bezier: UIBezierPath, scalingFactor: CGFloat, toLayer layer: CAShapeLayer) {
        let scalingTransform = CGAffineTransform(scaleX: scalingFactor, y: scalingFactor)
        
        let dPatch = UIBezierPath(cgPath: bezier.cgPath)
        dPatch.apply(scalingTransform)
        layer.path = dPatch.cgPath
    }
}
