import UIKit

class AppBannerController: UIViewController {
    static let StoryboardName = "AppBanner"
    static let StoryboardIdentifier = "CleverPushBanner"
    
    //MARK: Properties
    var data: Banner?
    
    @IBOutlet weak var bannerBody: UIView!
    @IBOutlet weak var bannerBodyContent: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let data = data else { return; }
        
        view.backgroundColor = UIColor.black.withAlphaComponent(0.0)
        let tapGetsure = UITapGestureRecognizer(target: self, action: #selector(self.onDismiss))
        tapGetsure.delegate = self
        tapGetsure.cancelsTouchesInView = true
        tapGetsure.numberOfTapsRequired = 1
        
        view.addGestureRecognizer(tapGetsure)
        view.isUserInteractionEnabled = true
        
        bannerBody.layer.cornerRadius = 15.0
        bannerBody.transform = CGAffineTransform(translationX: 0.0, y: view.bounds.height)
        
        composeBanner(blocks: data.blocks)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        fadeIn()
        jumpIn()
    }
    
    static func show(forBanner banner: Banner) -> AppBannerController? {
        guard let keyWindow = UIApplication.shared.windows.filter({$0.isKeyWindow}).first else {
            return nil
        }

        guard var topController = keyWindow.rootViewController else {
            return nil
        }
        
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        
        var appBannerController: AppBannerController? = nil
        if #available(iOS 13.0, *) {
            appBannerController = UIStoryboard(
                name: StoryboardName, bundle: nil
            ).instantiateViewController(identifier: StoryboardIdentifier) as? AppBannerController
        } else {
            appBannerController = UIStoryboard(
                name: StoryboardName, bundle: nil
            ).instantiateViewController(withIdentifier: StoryboardIdentifier) as? AppBannerController
        }
        
        if(appBannerController == nil) { return nil }
        
        appBannerController?.data = banner
        appBannerController?.modalPresentationStyle = .custom
        appBannerController?.modalTransitionStyle = .crossDissolve
        
        DispatchQueue.main.async {
            topController.present(appBannerController!, animated: false)
        }
        
        return appBannerController
    }
    
    private func composeBanner(blocks: [BannerBlock]) {
        var prevView: UIView? = nil
        for (index, block) in blocks.enumerated() {
            let parentConstraint: ParentConstraint? = index == 0 ? .top : index == blocks.count - 1 ? .bottom : nil
            
            switch block.type {
            case .button:
                let bannerBlockData = block as! BannerButtonBlock
                let buttonView = composeButtonBlock(bannerBlockData)
                
                activateItemConstrants(buttonView, prevView: prevView, parentConstraint: parentConstraint)
                
                prevView = buttonView
            case .text:
                let bannerTextData = block as! BannerTextBlock
                let textView = composeTextBlock(bannerTextData)
                
                activateItemConstrants(textView, prevView: prevView, parentConstraint: parentConstraint)
                
                prevView = textView
            case .image:
                let bannerImageData = block as! BannerImageBlock
                let imageView = composeImageBlock(bannerImageData)
                
                activateItemConstrants(imageView, prevView: prevView, parentConstraint: parentConstraint)
                
                prevView = imageView
            }
        }
    }
    
    private func composeButtonBlock(_ block: BannerButtonBlock) -> UIView {
        let button = UIButton()
        button.setTitle(block.text, for: UIControl.State.normal)
        button.setTitleColor(UIColor(hex: block.color), for: .normal)
        button.titleLabel?.font = button.titleLabel?.font.withSize(CGFloat(block.size) * 1.2)
        switch block.alignment {
        case .center:
            button.contentHorizontalAlignment = .center
        case .left:
            button.contentHorizontalAlignment = .left
        case .right:
            button.contentHorizontalAlignment = .right
        }
        button.backgroundColor = UIColor(hex: block.background)
        button.contentEdgeInsets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = CGFloat(block.radius)
        button.addTarget(self, action: #selector(self.onDismiss), for: .touchUpInside)
        
        button.setContentCompressionResistancePriority(UILayoutPriority(1000), for: .vertical)
        bannerBodyContent.addSubview(button)
        
        return button
    }
    
    private func composeTextBlock(_ block: BannerTextBlock) -> UIView {
        let label = UILabel()
        
        label.text = block.text
        label.textColor = UIColor(hex: block.color)
        label.font = label.font.withSize(CGFloat(block.size) * 1.2)
        
        // label.bounds = CGRect(x: 0.0, y: 0.0, width: 100.0, height: 100.0)
        // label.setContentHuggingPriority(UILayoutPriority(1000), for: .horizontal)
        //label.setContentHuggingPriority(UILayoutPriority(1000), for: .vertical)
        //label.setContentCompressionResistancePriority(UILayoutPriority(1000), for: .horizontal)
        label.setContentCompressionResistancePriority(UILayoutPriority(1000), for: .vertical)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        
        switch block.alignment {
        case .center:
            label.textAlignment = .center
        case .left:
            label.textAlignment = .left
        case .right:
            label.textAlignment = .right
        }
        
        bannerBodyContent.addSubview(label)
        
        return label
    }
    
    private func composeImageBlock(_ block: BannerImageBlock) -> UIView {
        let imageView = UIImageView()
        imageView.downloaded(from: block.imageUrl)
        
        let AspectRatio = CGFloat(block.scale) / 100
        let imageWidthConstraint = NSLayoutConstraint(
            item: imageView, attribute: NSLayoutConstraint.Attribute.width,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: bannerBodyContent, attribute: NSLayoutConstraint.Attribute.width,
            multiplier: AspectRatio,
            constant: 0
        )
        imageWidthConstraint.priority = UILayoutPriority(1000)
        let imageHeightConstraint = NSLayoutConstraint(
            item: imageView, attribute: NSLayoutConstraint.Attribute.height,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: bannerBodyContent, attribute: NSLayoutConstraint.Attribute.width,
            multiplier: AspectRatio,
            constant: 0
        )
        imageHeightConstraint.priority = UILayoutPriority(1000)
        let imageWidthCenterConstraint = NSLayoutConstraint(
            item: imageView, attribute: NSLayoutConstraint.Attribute.centerX,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: bannerBodyContent, attribute: NSLayoutConstraint.Attribute.centerX,
            multiplier: 1,
            constant: 0
        )
        imageWidthCenterConstraint.priority = UILayoutPriority(1000)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        bannerBodyContent.addSubview(imageView)
        bannerBodyContent.addConstraints([
            imageWidthConstraint,
            imageHeightConstraint,
            imageWidthCenterConstraint
        ])
        
        return imageView
    }
    
    private func activateItemConstrants(_ view: UIView, prevView: UIView? = nil, parentConstraint: ParentConstraint? = nil) {
        guard let bannerBodyContent = bannerBodyContent else { return; }
        
        let rightConstraint = NSLayoutConstraint(
            item: bannerBodyContent, attribute: NSLayoutConstraint.Attribute.trailing,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: view, attribute: NSLayoutConstraint.Attribute.trailing,
            multiplier: 1,
            constant: 0
        )
        rightConstraint.priority = UILayoutPriority(900.0)
        
        let leftConstraint = NSLayoutConstraint(
            item: view, attribute: NSLayoutConstraint.Attribute.leading,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: bannerBodyContent, attribute: NSLayoutConstraint.Attribute.leading,
            multiplier: 1,
            constant: 0
        )
        leftConstraint.priority = UILayoutPriority(900.0)
        
        let topParentConstraint = NSLayoutConstraint(
            item: view, attribute: NSLayoutConstraint.Attribute.top,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: bannerBodyContent, attribute: NSLayoutConstraint.Attribute.top,
            multiplier: 1,
            constant: 0
        )
        topParentConstraint.priority = UILayoutPriority(1000.0)
        
        let bottomParentConstraint = NSLayoutConstraint(
            item: bannerBodyContent, attribute: NSLayoutConstraint.Attribute.bottom,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: view, attribute: NSLayoutConstraint.Attribute.bottom,
            multiplier: 1,
            constant: 0
        )
        bottomParentConstraint.priority = UILayoutPriority(1000.0)
        
        bannerBodyContent.addConstraints([leftConstraint, rightConstraint])
        
        switch parentConstraint {
        case .none:
            let topConstraint = NSLayoutConstraint(
                item: view, attribute: NSLayoutConstraint.Attribute.top,
                relatedBy: NSLayoutConstraint.Relation.equal,
                toItem: prevView, attribute: NSLayoutConstraint.Attribute.bottom,
                multiplier: 1,
                constant: 15
            )
            topConstraint.priority = UILayoutPriority(1000.0)
            
            bannerBodyContent.addConstraint(topConstraint)
        case .top:
            bannerBodyContent.addConstraint(topParentConstraint)
        case .bottom:
            let topConstraint = NSLayoutConstraint(
                item: view, attribute: NSLayoutConstraint.Attribute.top,
                relatedBy: NSLayoutConstraint.Relation.equal,
                toItem: prevView, attribute: NSLayoutConstraint.Attribute.bottom,
                multiplier: 1,
                constant: 15
            )
            topConstraint.priority = UILayoutPriority(1000.0)
            bannerBodyContent.addConstraint(topConstraint)
            bannerBodyContent.addConstraint(bottomParentConstraint)
        }
    }
}

enum ParentConstraint {
    case top, bottom
}

extension AppBannerController: UIGestureRecognizerDelegate {
    @objc func onDismiss() {
        DispatchQueue.main.async {
            self.fadeOut()
            self.jumpOut { self.dismiss(animated: false, completion: nil) }
        }
    
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return self.view == touch.view
    }
}

extension AppBannerController {
    func fadeIn() {
        UIView.animate(withDuration: 0.3) {
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        }
    }
    
    func fadeOut() {
        UIView.animate(withDuration: 0.3) {
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.0)
        }
    }
    
    func jumpIn() {
        UIView.animate(
            withDuration: 0.65,
            delay: 0,
            usingSpringWithDamping: 0.75,
            initialSpringVelocity: 0.1
        ) {
            self.bannerBody.transform = CGAffineTransform(translationX: 0, y: 0)
        }
    }
    
    func jumpOut(_ completion: @escaping () -> Void) {
        UIView.animate(
            withDuration: 0.65,
            delay: 0,
            usingSpringWithDamping: 0.75,
            initialSpringVelocity: 0.1,
            //options: UIView.AnimationOptions.init(),
            animations: {
                self.bannerBody.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
            },
            completion: { _ in completion() }
        )
    }
}
