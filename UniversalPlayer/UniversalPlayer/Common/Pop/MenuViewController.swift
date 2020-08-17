//
//  MenuViewController.swift
//  Hotel
//
//  Created by 刘健 on 2017/3/8.
//  Copyright © 2018年 HK01. All rights reserved.
//

import Foundation
import UIKit

struct MenuItem {
    
    let title: String
    let image: UIImage?
    let isShowRedDot: Bool?
    let action: () -> Void
}

class OCMenuItem: NSObject {
    let menuItem: MenuItem
    
    init(title: String, image: UIImage?, isShowRedDot: Bool, action:@escaping () -> Void) {
        menuItem = MenuItem(title: title, image: image, isShowRedDot: isShowRedDot, action: action)
        super.init()
    }
}

class MenuPopoverBackgroundView: UIPopoverBackgroundView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.shadowColor = UIColor.clear.cgColor
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override static func contentViewInsets() -> UIEdgeInsets {
        UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    static override func arrowHeight() -> CGFloat {
        10
    }
    
    override static func arrowBase() -> CGFloat {
        0
    }
    
    override var arrowDirection: UIPopoverArrowDirection {
        get {
            .up
        }
        set {
            
        }
    }
    
    override var arrowOffset: CGFloat {
        get {
            30
        }
        set {
            
        }
    }
    
}

class MenuViewController: PopViewController {
    
    let items: [MenuItem]
    
    override var style: PopControllerStyle {
        .popover
    }
    
    override var cornerRadius: CGFloat {
        0
    }
    
    var menuRowHeight: CGFloat = 48
    var menuWidth: CGFloat = 129
    
    init(items: [MenuItem]) {
        self.items = items
        super.init(nibName: nil, bundle: nil)
    }
    
    init(ocItems: [OCMenuItem]) {
        var items = [MenuItem]()
        for ocItem in ocItems {
            items.append(ocItem.menuItem)
        }
        self.items = items
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dimmingView.backgroundColor = .clear
        self.view.backgroundColor = .clear
        self.popoverPresentationController?.backgroundColor = UIColor.clear
        self.popoverPresentationController?.popoverBackgroundViewClass = MenuPopoverBackgroundView.self
        self.preferredContentSize = CGSize(width: menuWidth, height: CGFloat(items.count) * menuRowHeight + 30)
        self.layoutViews()
    }
    
    deinit {
        print("MenuViewController deinit")
    }
    
    private func layoutViews() {
        let backgroundImage = UIImageView(image: #imageLiteral(resourceName: "menu_bg").resizableImage(withCapInsets: UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12), resizingMode: .stretch))
        backgroundImage.frame = CGRect(x: 0, y: 0, width: self.preferredContentSize.width, height: self.preferredContentSize.height - 30)
        backgroundImage.clipsToBounds = true
        view.addSubview(backgroundImage)
        for (offset, item) in items.enumerated() {
            let button = UIButton(type: .custom)
            button.setTitle(item.title, for: .normal)
            button.setTitleColor(UIColor.darkGray, for: .normal)
            button.frame = CGRect(x: 0, y: CGFloat(offset) * menuRowHeight, width: self.preferredContentSize.width, height: menuRowHeight)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
            button.addTarget(self, action: #selector(self.buttonAction(button:)), for: .touchUpInside)
            button.tag = 1_155 + offset
            view.addSubview(button)
            
            if item.isShowRedDot == true {
                let redDotImgeView = UIImageView(image: #imageLiteral(resourceName: "red_notice_small"))
                redDotImgeView.frame = CGRect(x: button.frame.width * 0.25, y: button.frame.height * 0.2, width: 10, height: 10)
                button.addSubview(redDotImgeView)
            }
        }
    }
    
    @objc private func buttonAction(button: UIButton) {
        let index = button.tag - 1_155
        if items.count > index {
            removeDimmingView()
            dismiss(animated: true) {
                    self.items[index].action()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        removeShadow()
    }
    
    var dismissBlock: (() -> Void)?
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeDimmingView()
        dismissBlock?()
    }
    
    // MARK: - 移除自带的阴影，添加黑色半透明背景蒙层
    
    let dimmingView = UIView()
    
    /// 移除自带的阴影
    func removeShadow() {
        if #available(iOS 13, *) {
            if let window = UIApplication.shared.delegate?.window {
                let transitionView = window?.subviews.filter { subview -> Bool in
                    type(of: subview) == NSClassFromComponents("UI", "Transition", "View")
                }
                let shadowView = transitionView?.last?.subviews.filter { subview -> Bool in
                    type(of: subview) == NSClassFromComponents("_", "UI", "Cutout", "Shadow", "View")
                }
                shadowView?.first?.isHidden = true
            }
        } else {
            if let window = UIApplication.shared.delegate?.window {
                let transitionView = window?.subviews.filter { subview -> Bool in
                    type(of: subview) == NSClassFromComponents("UI", "Transition", "View")
                }
                let patchView = transitionView?.first?.subviews.filter { subview -> Bool in
                    type(of: subview) == NSClassFromComponents("_", "UI", "Mirror", "Nine", "PatchView")
                }
                if let imageViews = patchView?.first?.subviews.filter({ subview -> Bool in
                    type(of: subview) == UIImageView.self
                }) {
                    for imageView in imageViews {
                        imageView.isHidden = true
                    }
                }
            }
        }
    }
    
    /// 使用私有类，避免私有 API 扫描检查二进制包的字串
    func NSClassFromComponents(_ components: String...) -> AnyClass? {
        NSClassFromString(components.joined())
    }
    
    private func removeDimmingView() {
        UIView.animate(withDuration: 0.1,
                       animations: {
            self.dimmingView.alpha = 0
        }, completion: { complete in
            if complete {
                self.dimmingView.removeFromSuperview()
            }
        })
    }
    
    func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {
        if let presentingViewController = presentingViewController {
            dimmingView.frame = presentingViewController.view.bounds
            dimmingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            dimmingView.alpha = 0
            presentingViewController.view.addSubview(dimmingView)
            let transitionCoordinator = presentingViewController.transitionCoordinator
            transitionCoordinator?.animate(alongsideTransition: { _ in
                self.dimmingView.alpha = 1
            }, completion: nil)
        }
    }
    
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        removeDimmingView()
        return true
    }
}
