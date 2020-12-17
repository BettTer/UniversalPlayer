//
//  BaseExtensions.swift
//  MikuMiku2.0
//
//  Created by XYoung on 2019/4/2.
//  Copyright © 2019 timedomAIn. All rights reserved.
//

import UIKit
import Photos
import AVFoundation

// MARK: - 最最基础 ==============================
extension NSObject {
    /// 获取对象所属类名
    @objc public var className: String {
//        return NSStringFromClass(type(of: self)).components(separatedBy: ".").last!
        return String(describing: type(of: self))
        
    }
    
}

// MARK: - 控制器 ==============================
extension UIViewController {
    /// 获取当前控制器头部高度
    public func getStatusBarAndNaviBarHeight() -> CGFloat {
        return UIApplication.shared.statusBarFrame.size.height + self.navigationController!.navigationBar.height()
        
    }// funcEnd
    
    /// 从故事板中初始化一个控制器 [控制器名] -> UIViewController
    static public func createVCFromStoryboard(storyboardName: String = "Main", with viewControllerID: String) -> UIViewController {
        
        let storyboard = UIStoryboard.init(name: storyboardName, bundle: Bundle.main)
        return storyboard.instantiateViewController(withIdentifier: viewControllerID)
        
    }// funcEnd
    
    /// 根据控制器类名&参数表(字典)创建控制器对象
    static public func createClassObjWithString(className: String!, classPropertyParam: Dictionary<String, Any>?) -> UIViewController {
        
        // * 动态获取命名空间
        let nameSpace = Bundle.main.infoDictionary!["CFBundleExecutable"] as! String
        
        // * 注意工程中必须有相关的类，否则程序会崩
        let viewControllerClass: AnyClass = NSClassFromString(nameSpace + "." + className)!
        
        // * 告诉编译器它的真实类型
        guard let classType = viewControllerClass as? UIViewController.Type else{
            print("无法获取到该控制器类型 在此跳出")
            return UIViewController()
        }
        
        let viewController = classType.init()
        if classPropertyParam != nil {
            viewController.setValuesForKeys(classPropertyParam!)
            
        }
        
        return viewController
    }
    
}

extension UIAlertController {
    static func quickInit(title: String,
                                message: String? = nil,
                                preferredStyle: UIAlertController.Style = .actionSheet,
                                optionTitles: [String],
                                optionActions: [() -> Void]) -> UIAlertController {
    
        let alertController = UIAlertController.init(title: title, message: message, preferredStyle: preferredStyle)
        
        for optionIndex in 0 ..< optionTitles.count {
            
            let alertAction = UIAlertAction.init(
                title: optionTitles[optionIndex],
                style: .default,
                handler: { (action) in
                    optionActions[optionIndex]()
                    
            })
            
            alertController.addAction(alertAction)
            
        }
        
        alertController.addAction(UIAlertAction.init(
            title: "取消",
            style: .cancel,
            handler: nil))
        
        
        return alertController
    }
    
}

// MARK: - UIView相关 ==============================
extension UIView {
    
    /// 获取当前View的横坐标
    public func x() -> CGFloat {
        return self.frame.origin.x
    }
    
    /// 获取当前View的纵坐标
    public func y() -> CGFloat {
        return self.frame.origin.y
    }
    
    /// 获取当前View的宽
    public func width() -> CGFloat {
        return self.frame.width
    }
    
    /// 获取当前View的高
    public func height() -> CGFloat {
        return self.frame.height
    }
    
    /// 获取当前View底部的CGFloat
    public func getBottom() -> CGFloat {
        return self.frame.origin.y + self.frame.height
    }
    
    /// 当前View截图 (是否不透明)
    @objc public func normalShot(isOpaque: Bool, scale: CGFloat) -> UIImage {
        // 参数①：截屏区域  参数②：是否透明  参数③：清晰度
        UIGraphicsBeginImageContextWithOptions(self.frame.size, isOpaque, scale)
        self.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext();
        return image;
    }
    
    /// 特殊View(渲染类)截图
    public func offScreenshot(isOpaque: Bool, scale: CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.frame.size, isOpaque, scale)
        _ = self.drawHierarchy(in: self.bounds, afterScreenUpdates: false)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    
    static private var BorderLayersKey = "BorderLayersKey"
    private var borderLayers: [CAShapeLayer]? {
        set {
            objc_setAssociatedObject(self, &UIView.BorderLayersKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
        }
        
        get {
            return objc_getAssociatedObject(self, &UIView.BorderLayersKey) as! [CAShapeLayer]?
            
        }
    }
    
    
    /// 设置可选圆角与边框(外)
    /// - Parameters:
    ///   - corners: 需要圆角的部位
    ///   - radii: 圆角半径(⚠️: 大于高的一半时会失效)
    ///   - borderColor: 边框颜色
    ///   - borderWidth: 边框宽度
    /// - Returns: Void
    public func setCornerAndBorder(
        byRoundingCorners corners: UIRectCorner?,
        radii: CGFloat?,
        borderColor: UIColor?,
        borderWidth: CGFloat?) -> Void {
        
        let needCorners: Bool = (corners != nil)
        let needBorder: Bool = (borderColor != nil)
        
        if needCorners == false && needBorder == false  {
            return
            
        }
        
        /// 遮罩线
        var maskPath: UIBezierPath
        
        if needCorners {
            maskPath = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners!, cornerRadii: CGSize(width: radii!, height: radii!))
            
        }else {
            maskPath = UIBezierPath(rect: self.bounds)
            
        }
        
        let maskLayer = CAShapeLayer.init()
        maskLayer.path = maskPath.cgPath
        self.layer.mask = maskLayer
        
        if needBorder {
            
            // * 如果有之前的 先清掉
            if let _ = borderLayers {
                for borderLayer in borderLayers! {
                    borderLayer.removeFromSuperlayer()
                    
                }
                
                borderLayers!.removeAll()
            }
            
            borderLayers = []
            
            /// 边框线
            let borderPath = UIBezierPath.init(rect: self.bounds)
            self.setBorder(byRoundingPath: borderPath, color: borderColor!, width: borderWidth! * 2)
            
            if needCorners {
                
                if corners!.contains(.bottomRight) {
                    let arcCenter = CGPoint.init(
                        x: self.bounds.width - radii!,
                        y: self.bounds.height - radii!)
                    let bottomRightCornerPath = UIBezierPath.init(arcCenter: arcCenter, radius: radii!, startAngle: 0, endAngle: CGFloat.pi / 2, clockwise: true)
                    self.setBorder(byRoundingPath: bottomRightCornerPath, color: borderColor!, width: borderWidth! * 2)
                }
                
                if corners!.contains(.bottomLeft) {
                    let arcCenter = CGPoint.init(
                        x: radii!,
                        y: self.bounds.height - radii!)
                    let bottomRightCornerPath = UIBezierPath.init(arcCenter: arcCenter, radius: radii!, startAngle: CGFloat.pi / 2, endAngle: CGFloat.pi, clockwise: true)
                    self.setBorder(byRoundingPath: bottomRightCornerPath, color: borderColor!, width: borderWidth! * 2)
                }

                if corners!.contains(.topLeft) {
                    let arcCenter = CGPoint.init(
                        x: radii!,
                        y: radii!)
                    let bottomRightCornerPath = UIBezierPath.init(arcCenter: arcCenter, radius: radii!, startAngle: CGFloat.pi, endAngle: CGFloat.pi * 3 / 2, clockwise: true)
                    self.setBorder(byRoundingPath: bottomRightCornerPath, color: borderColor!, width: borderWidth! * 2)


                }

                if corners!.contains(.topRight) {
                    let arcCenter = CGPoint.init(
                        x: self.bounds.width - radii!,
                        y: radii!)
                    let bottomRightCornerPath = UIBezierPath.init(arcCenter: arcCenter, radius: radii!, startAngle: CGFloat.pi * 3 / 2, endAngle: 0, clockwise: true)
                    self.setBorder(byRoundingPath: bottomRightCornerPath, color: borderColor!, width: borderWidth! * 2)
                }
                
            }
            
        }
        
        
    }
    
    /// 添加边框
    private func setBorder(
        byRoundingPath path: UIBezierPath,
        color: UIColor,
        width: CGFloat) -> Void {
        
        /// 边框Layer
        let borderShapeLayer = CAShapeLayer.init()
        borderShapeLayer.path = path.cgPath
        
        borderShapeLayer.strokeColor = color.cgColor
        borderShapeLayer.fillColor = UIColor.clear.cgColor
        borderShapeLayer.lineWidth = width
        
        self.layer.addSublayer(borderShapeLayer)
        
        if let _ = borderLayers {
            borderLayers!.append(borderShapeLayer)
            
        }
        
    }
    
    
    /// 添加阴影
    private func dropShadow(color: UIColor, opacity: Float = 0.5, offSet: CGSize, radius: CGFloat = 1, scale: Bool = true) {
        layer.masksToBounds = true
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowOffset = offSet
        layer.shadowRadius = radius
        
        layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
        layer.shouldRasterize = true
        layer.rasterizationScale = scale ? UIScreen.main.scale : 1
    }
    
    /// 抖动方向
    public enum ShakeDirection: Int{
        /// 水平
        case horizontal
        /// 垂直
        case vertical
    }
    
    /// - Parameters:
    ///   - direction: 抖动方向（默认是水平方向）
    ///   - times: 抖动次数（默认5次）
    ///   - interval: 每次抖动时间（默认0.1秒）
    ///   - delta: 抖动偏移量（默认2）
    ///   - completion: 抖动动画结束后的回调
    /// UIView的抖动方法
    private func shake(direction: ShakeDirection = .horizontal, times: Int = 16, interval: TimeInterval = 0.01, delta: CGFloat = 3.5, completion: (() -> Void)? = nil)
    {
        UIView.animate(withDuration: interval, animations: {
            
            switch direction
            {
            case .horizontal:
                self.layer.setAffineTransform(CGAffineTransform(translationX: delta, y: 0))
            case .vertical:
                self.layer.setAffineTransform(CGAffineTransform(translationX: 0, y: delta))
            }
        }) { (finish) in
            
            if times == 0
            {
                UIView.animate(withDuration: interval, animations: {
                    self.layer.setAffineTransform(CGAffineTransform.identity)
                }, completion: { (finish) in
                    completion?()
                })
            }
            else
            {
                self.shake(direction: direction, times: times - 1, interval: interval, delta: -delta, completion: completion)
            }
        }
    }
    
}

extension CALayer {
    
    /// 设置常用属性
    ///
    /// - Parameters:
    ///   - cornerRadius: 圆角值
    ///   - borderColor: 边框颜色
    ///   - borderWidth: 边框宽
    public func setCommonProperties(cornerRadius: CGFloat?,
                                    borderColor: UIColor?,
                                    borderWidth: CGFloat?) -> Void {
        
        self.masksToBounds = true
        
        if let radius = cornerRadius {
            self.cornerRadius = radius
            
        }
        
        if let color = borderColor {
            self.borderColor = color.cgColor
            self.borderWidth = borderWidth!
        }
        
    }
    
}

//extension UILabel {
//    /// 设置Label为动态行高
//    public func setAutoFitHeight(x: CGFloat, y: CGFloat, width: CGFloat) -> CGFloat {
//        self.numberOfLines = 0
//        self.lineBreakMode = NSLineBreakMode.byWordWrapping
//        let autoSize: CGSize = self.sizeThatFits(CGSize.init(width: width, height: CGFloat(MAXFLOAT)))
//        self.frame = CGRect.init(x: x, y: y, width: width, height: autoSize.height)
//        return autoSize.height
//    }
//
//    /// 设置Label为动态宽
//    public func setAutoFitWidth(x: CGFloat, y: CGFloat, height: CGFloat) -> CGFloat {
//        self.numberOfLines = 0
//        self.lineBreakMode = NSLineBreakMode.byWordWrapping
//        let autoSize: CGSize = self.sizeThatFits(CGSize.init(width: CGFloat(MAXFLOAT), height: height))
//        self.frame = CGRect.init(x: x, y: y, width: autoSize.width, height: height)
//        return autoSize.width
//    }
//}
//
//extension UITextField {
//    /// 设置UITextField为动态宽
//    public func setAutoFitWidth() -> CGFloat {
//        let autoSize: CGSize = self.sizeThatFits(CGSize.init(width: CGFloat(MAXFLOAT), height: self.height()))
//        self.frame = CGRect.init(x: self.x(), y: self.y(), width: autoSize.width, height: self.height())
//        return autoSize.width
//    }
//
//}
//
//extension UITextView {
//    @objc func setAutoFitHeight(text: String, font: UIFont, fixedWidth: CGFloat) -> CGFloat {
//        self.text = text
//        self.font = font
//
//        let size = CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude)
//        let fixedFrame = self.sizeThatFits(size)
//
//        return fixedFrame.height
//    }
//}

extension UITouch {
    public enum TouchStatus {
        /// 开始
        case Began
        /// 滑动
        case Moved
        /// 结束
        case Ended
        /// 取消
        case Cancel
        /// 初始化
        case Init
    }
    
    /// 触摸状态
    var touchStatus: TouchStatus {
        set {
            objc_setAssociatedObject(self, &AssociatedKey.touchStatusKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
        }
        
        get {
            if let status = objc_getAssociatedObject(self, &AssociatedKey.touchStatusKey) as? TouchStatus {
                return status
                
            }
            
            return .Init
        }
    }
    
    /// 滑动轨迹ID
    var movedPathID: String {
        get {
            return String(format: "%p",  self)
            
        }
    }
    
    /// 创建时间
    var produceTime: Double {
        set {
            objc_setAssociatedObject(self, &AssociatedKey.produceTouchTime, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        
        get {
            return objc_getAssociatedObject(self, &AssociatedKey.produceTouchTime) as! Double
        }
        
    }
    
    /// 初始触摸点
    var oriTouchPoint: CGPoint {
        set {
            objc_setAssociatedObject(self, &AssociatedKey.oriTouchPoint, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        
        get {
            return objc_getAssociatedObject(self, &AssociatedKey.oriTouchPoint) as! CGPoint
        }
        
    }
    
}

// MARK: - 视觉 ==============================
extension CGRect {
    func adaptiveFrame(basicType: EnumSet.iPhoneType = .iPhonePlus) -> CGRect {
        let currentScreenSize = CGSize.init(
            width: CGFloat.screenWidth(),
            height: CGFloat.screenHeight())
        
        var basicScreenSize = EnumSet.screenSize(type: basicType)
        if currentScreenSize.width > currentScreenSize.height {
            basicScreenSize = CGSize.init(width: basicScreenSize.height, height: basicScreenSize.width)
            
        }
        
        let adaptiveFrame = CGRect.init(
            x: self.origin.x / basicScreenSize.width * currentScreenSize.width,
            y: self.origin.y / basicScreenSize.height * currentScreenSize.height,
            width: self.width / basicScreenSize.width * currentScreenSize.width,
            height: self.height / basicScreenSize.width * currentScreenSize.width)
        
        
        return adaptiveFrame
    }
    
    static public func frameOfScreen() -> CGRect {
        return CGRect.init(x: 0, y: 0, width: CGFloat.screenWidth(), height: CGFloat.screenHeight())
    }
    
}

extension CGFloat {
    static public func screenWidth() -> CGFloat {
        return UIScreen.main.bounds.size.width
        
    }
    
    static public func screenHeight() -> CGFloat {
        return UIScreen.main.bounds.size.height
        
    }
    
}

extension UIColor {
    /// 十六进制字符串初始化颜色
    @objc static public func hexadecimalColor(_ hexadecimal: String, alpha: CGFloat = 1) -> UIColor {
        var cstr = hexadecimal.trimmingCharacters(in:  CharacterSet.whitespacesAndNewlines).uppercased() as NSString;
        if(cstr.length < 6){
            return UIColor.clear;
        }
        if(cstr.hasPrefix("0X")){
            cstr = cstr.substring(from: 2) as NSString
        }
        if(cstr.hasPrefix("#")){
            cstr = cstr.substring(from: 1) as NSString
        }
        if(cstr.length != 6){
            return UIColor.clear;
        }
        var range = NSRange.init()
        range.location = 0
        range.length = 2
        //r
        let rStr = cstr.substring(with: range);
        //g
        range.location = 2;
        let gStr = cstr.substring(with: range)
        //b
        range.location = 4;
        let bStr = cstr.substring(with: range)
        var r :UInt32 = 0x0;
        var g :UInt32 = 0x0;
        var b :UInt32 = 0x0;
        Scanner.init(string: rStr).scanHexInt32(&r);
        Scanner.init(string: gStr).scanHexInt32(&g);
        Scanner.init(string: bStr).scanHexInt32(&b);
        return UIColor.init(red: CGFloat(r)/255.0, green: CGFloat(g)/255.0, blue: CGFloat(b)/255.0, alpha: alpha);
        
    }
}

extension NSDate
{
    /// 时间戳转日期
    ///
    /// - Parameters:
    ///   - timeInterval: 时间戳
    ///   - unit: 单位
    /// - Returns: 结果字符串
    @objc static func getDateIntervalString(timeInterval: Double) -> String {
        
        let date = Date.init(timeIntervalSince1970: timeInterval / Double(EnumSet.TimeIntervalUnit.microsecond.rawValue))
        
        let formatter = DateFormatter()
        if date.isToday() {
            
            let interval = date.timeIntervalSinceNow
            if (interval < 60) {
                return "1分钟前"
            }else if ((Int(timeInterval/60)) < 60){
                let result = Int(timeInterval/60)
                return "\(result)分钟前"
            }else {
                let result = Int(timeInterval/(60*60))
                return "\(result)小时前"
            }
            
        }else if date.isYesterday(){
            //是昨天
            formatter.dateFormat = "昨天"
            return formatter.string(from: date)
        }else if date.isSameWeek(){
            //是同一周
            let week = date.weekdayStringFromDate()
            formatter.dateFormat = "\(week)"
            return formatter.string(from: date)
        }else{
            formatter.dateFormat = "MM/dd"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Data ==============================
extension Date {
    /// 获得现在的毫秒数
    static func getCurrentMSec() -> Int {
        return Int((Date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1)) * 1000)
        
    }
    
    /// 获取星期几
    func getWeekDay() -> Int {
        let interval = Int(self.timeIntervalSince1970) + TimeZone.current.secondsFromGMT()
        let days = Int(interval / 86400) // 24*60*60
        let weekday = ((days + 4) % 7 + 7) % 7
        
        return weekday == 0 ? 7 : weekday
    }
    
    /// 时间戳转日期
    ///
    /// - Parameters:
    ///   - timeInterval: 时间戳
    ///   - unit: 单位
    /// - Returns: 结果字符串
    static func getDateIntervalString(timeInterval: Double) -> String {
        
        let date = Date.init(timeIntervalSince1970: timeInterval / Double(EnumSet.TimeIntervalUnit.millisecond.rawValue))
        
        let formatter = DateFormatter()
        if date.isToday() {
    
            let interval = date.timeIntervalSinceNow
            if (interval < 60) {
                return "1分钟前"
            }else if ((Int(timeInterval/60)) < 60){
                let result = Int(timeInterval/60)
                return "\(result)分钟前"
            }else {
                let result = Int(timeInterval/(60*60))
                return "\(result)小时前"
            }
        
        }else if date.isYesterday(){
            //是昨天
            formatter.dateFormat = "昨天HH:mm"
            return formatter.string(from: date)
        }else if date.isSameWeek(){
            //是同一周
            let week = date.weekdayStringFromDate()
            formatter.dateFormat = "\(week)HH:mm"
            return formatter.string(from: date)
        }else{
            formatter.dateFormat = "MM/dd HH:mm"
            return formatter.string(from: date)
        }
    }
    
    /// 时间戳转日期
    ///
    /// - Parameters:
    ///   - timeInterval: 时间戳
    ///   - unit: 单位
    /// - Returns: 结果字符串
    static func getDateString(timeInterval: TimeInterval, unit: EnumSet.TimeIntervalUnit) -> String {
        
        let date = Date.init(timeIntervalSince1970: timeInterval / Double(unit.rawValue))
        
        let formatter = DateFormatter()
        if date.isToday() {
            //是今天
            formatter.dateFormat = "今天HH:mm"
            return formatter.string(from: date)
            
        }else if date.isYesterday(){
            //是昨天
            formatter.dateFormat = "昨天HH:mm"
            return formatter.string(from: date)
        }else if date.isSameWeek(){
            //是同一周
            let week = date.weekdayStringFromDate()
            formatter.dateFormat = "\(week)HH:mm"
            return formatter.string(from: date)
        }else{
            formatter.dateFormat = "MM/dd HH:mm"
            return formatter.string(from: date)
        }
    }
    
    func isToday() -> Bool {
        let calendar = Calendar.current
        //当前时间
        let nowComponents = calendar.dateComponents([.day,.month,.year], from: Date() )
        //self
        let selfComponents = calendar.dateComponents([.day,.month,.year], from: self as Date)
        
        return (selfComponents.year == nowComponents.year) && (selfComponents.month == nowComponents.month) && (selfComponents.day == nowComponents.day)
    }
    
    func isYesterday() -> Bool {
        let calendar = Calendar.current
        //当前时间
        let nowComponents = calendar.dateComponents([.day], from: Date() )
        //self
        let selfComponents = calendar.dateComponents([.day], from: self as Date)
        let cmps = calendar.dateComponents([.day], from: selfComponents, to: nowComponents)
        return cmps.day == 1
        
    }
    
    func isSameWeek() -> Bool {
        let calendar = Calendar.current
        //当前时间
        let nowComponents = calendar.dateComponents([.day,.month,.year], from: Date() )
        //self
        let selfComponents = calendar.dateComponents([.weekday,.month,.year], from: self as Date)
        
        return (selfComponents.year == nowComponents.year) && (selfComponents.month == nowComponents.month) && (selfComponents.weekday == nowComponents.weekday)
    }
    
    func weekdayStringFromDate() -> String {
        let weekdays:NSArray = ["星期日", "星期一", "星期二", "星期三", "星期四", "星期五", "星期六"]
        var calendar = Calendar.init(identifier: .gregorian)
        let timeZone = TimeZone.init(identifier: "Asia/Shanghai")
        calendar.timeZone = timeZone!
        let theComponents = calendar.dateComponents([.weekday], from: self as Date)
        return weekdays.object(at: theComponents.weekday!) as! String
    }
    
    
    /// 根据本地时区转换
    static func getNowDateFromatAnDate(_ anyDate: Date?) -> Date {
        //设置源日期时区
        let sourceTimeZone = NSTimeZone.init(forSecondsFromGMT: 0)
        //或GMT
        //设置转换后的目标日期时区
        let destinationTimeZone = NSTimeZone.init(forSecondsFromGMT: 8*3600)
        //得到源日期与世界标准时间的偏移量
        var sourceGMTOffset: Int? = nil
        if let aDate = anyDate {
            sourceGMTOffset = sourceTimeZone.secondsFromGMT(for: aDate)
        }
        //目标日期与本地时区的偏移量
        var destinationGMTOffset: Int? = nil
        if let aDate = anyDate {
            destinationGMTOffset = destinationTimeZone.secondsFromGMT(for: aDate)
        }
        //得到时间偏移量的差值
        let interval = TimeInterval((destinationGMTOffset ?? 0) - (sourceGMTOffset ?? 0))
        //转为现在时间
        var destinationDateNow: Date? = nil
        if let aDate = anyDate {
            destinationDateNow = Date(timeInterval: interval, since: aDate)
        }
        return destinationDateNow!
    }
    
}

extension String {
    public func cutWithPlaces(startPlace: Int,
                              endPlace: Int,
                              file: String = #file,
                              method: String = #function,
                              line: Int = #line) -> String {
        if self == "" {
            return ""
            
        }else {
            let startIndex = self.index(self.startIndex, offsetBy: startPlace)
            let endIndex = self.index(startIndex, offsetBy: endPlace - startPlace)
            
            return String(self[startIndex ..< endIndex])
        }
        
    }
    
    /// 生成一个随机字符串
    static public func random(_ count: Int) -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
        var ranStr = ""
        for _ in 0 ..< count {
            let index = Int.random(in: 0 ..< characters.count)
            ranStr.append(characters[characters.index(characters.startIndex, offsetBy: index)])
            
        }
        
        return ranStr
    }// funcEnd
    
    /// 使用正则表达式替换
    public func pregReplace(pattern: String?, with: String,
                            options: NSRegularExpression.Options = []) -> String {
        
        /// 只留汉字的正则表达式
        let OnlyChinesePattern = "[^\\u4E00-\\u9FA5]"
        
        
        let regex = try! NSRegularExpression(pattern: OnlyChinesePattern, options: options)
        
        let resultString = regex.stringByReplacingMatches(in: with, options: [],
                                                          range: NSMakeRange(0, with.count),
                                                          withTemplate: with)
        
        return resultString
    }
    
    /// 去除Emoji表情
    public func stringByRemovingEmoji() -> String {
        return String(self.filter { !$0.isEmoji() })
    }
    
    /// range转换为NSRange
    func nsRange(from range: Range<String.Index>) -> NSRange {
        return NSRange(range, in: self)
    }
}

extension Character {
    fileprivate func isEmoji() -> Bool {
        
        return Character(UnicodeScalar(UInt32(0x1d000))!) <= self && self <= Character(UnicodeScalar(UInt32(0x1f77f))!)
            || Character(UnicodeScalar(UInt32(0x2100))!) <= self && self <= Character(UnicodeScalar(UInt32(0x26ff))!)
    }
}

extension Double {
    /// 保留X位小数
    public func roundTo(places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

// MARK: - Int数字转汉字数字;
extension Int {
    /// Int数字转汉字数字
    var chineseNumber: String {
        get {
            if self == 0 {
                return "零"
            }
            let zhNumbers = ["零", "一", "二", "三", "四", "五", "六", "七", "八", "九"]
            let units = ["", "十", "百", "千", "万", "十", "百", "千", "亿", "十","百","千"]
            var cn = ""
            var currentNum = 0
            var beforeNum = 0
            let intLength = Int(floor(log10(Double(self))))
            for index in 0...intLength {
                currentNum = self/Int(pow(10.0,Double(index)))%10
                if index == 0{
                    if currentNum != 0 {
                        cn = zhNumbers[currentNum]
                        continue
                    }
                } else {
                    beforeNum = self/Int(pow(10.0,Double(index-1)))%10
                }
                if [1,2,3,5,6,7,9,10,11].contains(index) {
                    if currentNum == 1 && [1,5,9].contains(index) && index == intLength { // 处理一开头的含十单位
                        cn = units[index] + cn
                    } else if currentNum != 0 {
                        cn = zhNumbers[currentNum] + units[index] + cn
                    } else if beforeNum != 0 {
                        cn = zhNumbers[currentNum] + cn
                    }
                    continue
                }
                if [4,8,12].contains(index) {
                    cn = units[index] + cn
                    if (beforeNum != 0 && currentNum == 0) || currentNum != 0 {
                        cn = zhNumbers[currentNum] + cn
                    }
                }
            }
            return cn
        }
    }
}



// MARK: - 杂类 ==============================
extension CGRect {
    public static func screen() -> CGRect {
        return  CGRect.init(x: 0, y: 0,
                            width: CGFloat.screenWidth(),
                            height: CGFloat.screenHeight())
        
    }
    
    
}

extension UIImage {
    /// 把文件存储到沙盒
    public func saveToSandBox(fileName: String, searchPath: FileManager.SearchPathDirectory, folderName: String?) -> String? {
        guard let imageData = self.jpegData(compressionQuality: 1) else {
            return nil
            
        }
        
        guard let directory = try? FileManager.default.url(for: searchPath, in: .userDomainMask, appropriateFor: nil, create: false) as NSURL else {
            return nil
        }
        
        
        do {
            var finalURL: URL!
            
            if let folder = folderName {
                let tmpURL = directory.appendingPathComponent(folder, isDirectory: true)
                finalURL = tmpURL!.appendingPathComponent(fileName + ".JPEG")
                
            }else {
                finalURL = directory.appendingPathComponent(fileName + ".JPEG")!
                
            }
            
            try imageData.write(to: finalURL)
            
            return finalURL.path
            
        } catch {
            print(error.localizedDescription)
            
            return nil
        }
    }
    
    /// 从沙盒读取文件
    static public func load(filePath: String) -> UIImage? {
        let fileURL = URL.init(fileURLWithPath: filePath)
        do {
            let imageData = try Data(contentsOf: fileURL)
            return UIImage(data: imageData)
        } catch {
            print("Error loading image : \(error)")
        }
        return nil
    }
    
    /// 压缩图片质量
    public func compressByQuality(toByte maxLength: Int) -> UIImage {
        var compression: CGFloat = 1
        
        var data = self.jpegData(compressionQuality: compression)
        
        if data == nil {
            return self
        }
        
        
        if data!.count <= maxLength {
            return self
            
        }
        
        var max: CGFloat = 1
        var min: CGFloat = 0
        for _ in 0 ..< 6 {
            compression = (max + min) / 2
            data = self.jpegData(compressionQuality: compression)!
            if CGFloat(data!.count) < CGFloat(maxLength) * 0.9 {
                min = compression
            } else if data!.count > maxLength {
                max = compression
            } else {
                break
            }
        }
        return UIImage(data: data!)!
        
    }
    
    /// 纯色图片
    @objc static func solidColorImage(color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context!.setFillColor(color.cgColor)
        context!.fill(rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
}

extension URL {
    static func safeURL(
        pathDirectory: FileManager.SearchPathDirectory = .documentDirectory,
        lastPathComponent: String) -> URL {
        
        let prevURL = FileManager.default.urls(for: pathDirectory, in: .userDomainMask).first!
        
        return prevURL.appendingPathComponent(lastPathComponent)
        
    }
}

extension FileManager{
    /// 创建文件夹
    public func creatFilePath(path: String){
        
        do{
            // 创建文件夹   1，路径 2 是否补全中间的路劲 3 属性
            try self.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            
        } catch{
            
            print("creat false")
        }
        
        
    }
    
}

extension DispatchQueue {
    /// 顺序执行
    func sequentialExecution(workItem: @escaping () -> Void, notifyQueue: DispatchQueue?, notify: @escaping () -> Void) -> Void {
        
//        @convention(block)
//        @convention(block)
        
        let group = DispatchGroup.init()
        
        self.async(group: group, execute: {
            workItem()
            
        })
        
        if let queue = notifyQueue {
            group.notify(queue: queue) {
                notify()
                
            }
            
        }else {
            group.notify(queue: self) {
                notify()
                
            }
            
        }
        

        
    }
    
    private static var _onceTracker = [String]()
    
    public class func once(file: String = #file,
                           function: String = #function,
                           line: Int = #line,
                           block: () -> Void) {
        let token = "\(file):\(function):\(line)"
        once(token: token, block: block)
    }
    
    /**
     Executes a block of code, associated with a unique token, only once.  The code is thread safe and will
     only execute the code once even in the presence of multithreaded calls.
     
     - parameter token: A unique reverse DNS style name such as com.vectorform.<name> or a GUID
     - parameter block: Block to execute once
     */
    public class func once(token: String,
                           block: () -> Void) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        guard !_onceTracker.contains(token) else { return }
        
        _onceTracker.append(token)
        block()
    }
    
    
}

extension AVAudioSession {
    /// 询问麦克风权限
    static func authorizeToMicrophone(callBack: @escaping (Bool) -> Void){
        
        let session = AVAudioSession.sharedInstance()
        
        switch session.recordPermission {
            
        case .granted: // * 已授权
            callBack(true)
            
        case .denied: // * 已拒绝
            callBack(false)
            
        case .undetermined:  // * 未决定
            session.requestRecordPermission() { allowed in
                
                DispatchQueue.main.async {
                    if allowed {
                        callBack(true)
                    } else {
                        callBack(false)
                    }
                }
                
            }
            
        @unknown default:
            fatalError()
        }
        
    }
    
}


extension PHPhotoLibrary {
    /// 相册权限
    static func authorizeToAlbum(handler: @escaping (PHAuthorizationStatus) -> Void) {
        /*
         @available(iOS 8, *)
         case notDetermined = 0 // * 未决定

         @available(iOS 8, *)
         case restricted = 1 // * 无法访问且无法更改(例如已设置家长控制)
         
         @available(iOS 8, *)
         case denied = 2 // * 已拒绝

         @available(iOS 8, *)
         case authorized = 3 // * 完全访问

         @available(iOS 14, *)
         case limited = 4 // * 部分访问
         */
        
        var currentStatus: PHAuthorizationStatus!
        
        if #available(iOS 14, *) {
            currentStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            
        }else {
            currentStatus = PHPhotoLibrary.authorizationStatus()
            
        }
        
        if currentStatus == .notDetermined { // * 未决定 先请求授权
            
            if #available(iOS 14, *) {
                // * 请求授权
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { (futureStatus) in
                    handler(futureStatus)
                    
                }
                
            }else {
                // * 请求授权
                PHPhotoLibrary.requestAuthorization { (futureStatus) in
                    handler(futureStatus)
                    
                }
                
            }
            
            
        }else {
            handler(currentStatus)
            
        }
        
        
        
    }
}


extension UIDevice {
    /// 当前设备型号
    static let modelName: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        func mapToDevice(identifier: String) -> String { // swiftlint:disable:this cyclomatic_complexity
            #if os(iOS)
            switch identifier {
            case "iPod5,1":                                 return "iPod Touch 5"
            case "iPod7,1":                                 return "iPod Touch 6"
            case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
            case "iPhone4,1":                               return "iPhone 4s"
            case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
            case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
            case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
            case "iPhone7,2":                               return "iPhone 6"
            case "iPhone7,1":                               return "iPhone 6 Plus"
            case "iPhone8,1":                               return "iPhone 6s"
            case "iPhone8,2":                               return "iPhone 6s Plus"
            case "iPhone9,1", "iPhone9,3":                  return "iPhone 7"
            case "iPhone9,2", "iPhone9,4":                  return "iPhone 7 Plus"
            case "iPhone8,4":                               return "iPhone SE"
            case "iPhone10,1", "iPhone10,4":                return "iPhone 8"
            case "iPhone10,2", "iPhone10,5":                return "iPhone 8 Plus"
            case "iPhone10,3", "iPhone10,6":                return "iPhone X"
            case "iPhone11,2":                              return "iPhone XS"
            case "iPhone11,4", "iPhone11,6":                return "iPhone XS Max"
            case "iPhone11,8":                              return "iPhone XR"
            case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
            case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
            case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
            case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
            case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
            case "iPad6,11", "iPad6,12":                    return "iPad 5"
            case "iPad7,5", "iPad7,6":                      return "iPad 6"
            case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
            case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
            case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
            case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
            case "iPad6,3", "iPad6,4":                      return "iPad Pro (9.7-inch)"
            case "iPad6,7", "iPad6,8":                      return "iPad Pro (12.9-inch)"
            case "iPad7,1", "iPad7,2":                      return "iPad Pro (12.9-inch) (2nd generation)"
            case "iPad7,3", "iPad7,4":                      return "iPad Pro (10.5-inch)"
            case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4":return "iPad Pro (11-inch)"
            case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8":return "iPad Pro (12.9-inch) (3rd generation)"
            case "AppleTV5,3":                              return "Apple TV"
            case "AppleTV6,2":                              return "Apple TV 4K"
            case "AudioAccessory1,1":                       return "HomePod"
            case "i386", "x86_64":                          return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "iOS"))"
            default:                                        return identifier
            }
            #elseif os(tvOS)
            switch identifier {
            case "AppleTV5,3": return "Apple TV 4"
            case "AppleTV6,2": return "Apple TV 4K"
            case "i386", "x86_64": return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "tvOS"))"
            default: return identifier
            }
            #endif
        }
        
        return mapToDevice(identifier: identifier)
    }()
}

/// 扩展属性关联Key
private struct AssociatedKey {
    /// 当前touch状态Key
    static var touchStatusKey = "touchStatusKey"
    /// touch产生时间
    static var produceTouchTime = "produceTouchTime"
    /// touch初始位置
    static var oriTouchPoint = "oriTouchPoint"
}

// MARK: - 辅助数据 ==============================
class BaseExtensions: NSObject {
    
    
}

@objc public protocol NibloadProtocol {

}

extension NibloadProtocol where Self: UIView{
    /// 从Xib中初始化View
    static func loadFromNib(_ nibName: String? = nil) -> Self  {
        return Bundle.main.loadNibNamed(nibName ?? "\(self)", owner: nil, options: nil)?.first as! Self
    }
}
