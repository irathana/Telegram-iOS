import Foundation
import AsyncDisplayKit
import Display
import Postbox

class GalleryControllerNode: ASDisplayNode, UIScrollViewDelegate {
    var statusBar: StatusBar?
    var navigationBar: NavigationBar?
    let footerNode: GalleryFooterNode
    var toolbarNode: ASDisplayNode?
    var transitionNodeForCentralItem: (() -> ASDisplayNode?)?
    var dismiss: (() -> Void)?
    
    var containerLayout: (CGFloat, ContainerViewLayout)?
    var backgroundNode: ASDisplayNode
    var scrollView: UIScrollView
    var pager: GalleryPagerNode
    
    var beginCustomDismiss: () -> Void = { }
    var completeCustomDismiss: () -> Void = { }
    var baseNavigationController: () -> NavigationController? = { return nil }
    
    private var presentationState = GalleryControllerPresentationState()
    
    var areControlsHidden = false
    var isBackgroundExtendedOverNavigationBar = true {
        didSet {
            if let (navigationBarHeight, layout) = self.containerLayout {
                self.backgroundNode.frame = CGRect(origin: CGPoint(x: 0.0, y: self.isBackgroundExtendedOverNavigationBar ? 0.0 : navigationBarHeight), size: CGSize(width: layout.size.width, height: layout.size.height - (self.isBackgroundExtendedOverNavigationBar ? 0.0 : navigationBarHeight)))
            }
        }
    }
    
    init(controllerInteraction: GalleryControllerInteraction, pageGap: CGFloat = 20.0) {
        self.backgroundNode = ASDisplayNode()
        self.backgroundNode.backgroundColor = UIColor.black
        self.scrollView = UIScrollView()
        self.pager = GalleryPagerNode(pageGap: pageGap)
        self.footerNode = GalleryFooterNode(controllerInteraction: controllerInteraction)
        
        super.init(viewBlock: {
            return UITracingLayerView()
        }, didLoad: nil)
        
        self.pager.toggleControlsVisibility = { [weak self] in
            if let strongSelf = self {
                strongSelf.areControlsHidden = !strongSelf.areControlsHidden
                UIView.animate(withDuration: 0.3, animations: {
                    let alpha: CGFloat = strongSelf.areControlsHidden ? 0.0 : 1.0
                    strongSelf.navigationBar?.alpha = alpha
                    strongSelf.statusBar?.alpha = alpha
                    strongSelf.footerNode.alpha = alpha
                })
            }
        }
        
        self.pager.beginCustomDismiss = { [weak self] in
            if let strongSelf = self {
                strongSelf.beginCustomDismiss()
            }
        }
        
        self.pager.completeCustomDismiss = { [weak self] in
            if let strongSelf = self {
                strongSelf.completeCustomDismiss()
            }
        }
        
        self.pager.baseNavigationController = { [weak self] in
            return self?.baseNavigationController()
        }
        
        self.addSubnode(self.backgroundNode)
        
        self.scrollView.showsVerticalScrollIndicator = false
        self.scrollView.showsHorizontalScrollIndicator = false
        self.scrollView.alwaysBounceHorizontal = false
        self.scrollView.alwaysBounceVertical = false
        self.scrollView.clipsToBounds = false
        self.scrollView.delegate = self
        self.scrollView.scrollsToTop = false
        self.view.addSubview(self.scrollView)
        
        self.scrollView.addSubview(self.pager.view)
        self.addSubnode(self.footerNode)
    }
    
    func containerLayoutUpdated(_ layout: ContainerViewLayout, navigationBarHeight: CGFloat, transition: ContainedViewLayoutTransition) {
        self.containerLayout = (navigationBarHeight, layout)
        
        transition.updateFrame(node: self.backgroundNode, frame: CGRect(origin: CGPoint(x: 0.0, y: self.isBackgroundExtendedOverNavigationBar ? 0.0 : navigationBarHeight), size: CGSize(width: layout.size.width, height: layout.size.height - (self.isBackgroundExtendedOverNavigationBar ? 0.0 : navigationBarHeight))))
        
        transition.updateFrame(node: self.footerNode, frame: CGRect(origin: CGPoint(), size: layout.size))
        self.footerNode.updateLayout(layout, footerContentNode: self.presentationState.footerContentNode, transition: transition)
        
        let previousContentHeight = self.scrollView.contentSize.height
        let previousVerticalOffset = self.scrollView.contentOffset.y
        
        self.scrollView.frame = CGRect(origin: CGPoint(), size: layout.size)
        self.scrollView.contentSize = CGSize(width: 0.0, height: layout.size.height * 3.0)
        
        if previousContentHeight.isEqual(to: 0.0) {
            self.scrollView.contentOffset = CGPoint(x: 0.0, y: self.scrollView.contentSize.height / 3.0)
        } else {
            self.scrollView.contentOffset = CGPoint(x: 0.0, y: previousVerticalOffset * self.scrollView.contentSize.height / previousContentHeight)
        }
        
        self.pager.frame = CGRect(origin: CGPoint(x: 0.0, y: layout.size.height), size: layout.size)
        self.pager.containerLayoutUpdated(layout, navigationBarHeight: navigationBarHeight, transition: transition)
    }
    
    func animateIn(animateContent: Bool) {
        self.backgroundNode.backgroundColor = self.backgroundNode.backgroundColor?.withAlphaComponent(0.0)
        self.statusBar?.alpha = 0.0
        self.navigationBar?.alpha = 0.0
        self.footerNode.alpha = 0.0
        UIView.animate(withDuration: 0.2, animations: {
            self.backgroundNode.backgroundColor = self.backgroundNode.backgroundColor?.withAlphaComponent(1.0)
            self.statusBar?.alpha = 1.0
            self.navigationBar?.alpha = 1.0
            self.footerNode.alpha = 1.0
        })
        
        if let toolbarNode = self.toolbarNode {
            toolbarNode.layer.animatePosition(from: CGPoint(x: 0.0, y: self.bounds.size.height), to: CGPoint(), duration: 0.4, timingFunction: kCAMediaTimingFunctionSpring, additive: true)
        }
        
        if animateContent {
            self.scrollView.layer.animateBounds(from: self.scrollView.layer.bounds.offsetBy(dx: 0.0, dy: -self.scrollView.layer.bounds.size.height), to: self.scrollView.layer.bounds, duration: 0.4, timingFunction: kCAMediaTimingFunctionSpring)
        }
    }
    
    func animateOut(animateContent: Bool, completion: @escaping () -> Void) {
        var contentAnimationCompleted = true
        var interfaceAnimationCompleted = false
        
        let intermediateCompletion = {
            if contentAnimationCompleted && interfaceAnimationCompleted {
                completion()
            }
        }
        
        UIView.animate(withDuration: 0.25, animations: {
            self.backgroundNode.backgroundColor = self.backgroundNode.backgroundColor?.withAlphaComponent(0.0)
            self.statusBar?.alpha = 0.0
            self.navigationBar?.alpha = 0.0
            self.footerNode.alpha = 0.0
        }, completion: { _ in
            interfaceAnimationCompleted = true
            intermediateCompletion()
        })
        
        if let toolbarNode = self.toolbarNode {
            toolbarNode.layer.animatePosition(from: CGPoint(), to: CGPoint(x: 0.0, y: self.bounds.size.height), duration: 0.25, timingFunction: kCAMediaTimingFunctionLinear, removeOnCompletion: false, additive: true)
        }
        
        if animateContent {
            contentAnimationCompleted = false
            self.scrollView.layer.animateBounds(from: self.scrollView.layer.bounds, to: self.scrollView.layer.bounds.offsetBy(dx: 0.0, dy: -self.scrollView.layer.bounds.size.height), duration: 0.25, timingFunction: kCAMediaTimingFunctionLinear, removeOnCompletion: false, completion: { _ in
                contentAnimationCompleted = true
                intermediateCompletion()
            })
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let distanceFromEquilibrium = scrollView.contentOffset.y - scrollView.contentSize.height / 3.0
        
        let transition = 1.0 - min(1.0, max(0.0, abs(distanceFromEquilibrium) / 50.0))
        let backgroundTransition = 1.0 - min(1.0, max(0.0, abs(distanceFromEquilibrium) / 80.0))
        self.backgroundNode.backgroundColor = self.backgroundNode.backgroundColor?.withAlphaComponent(backgroundTransition)
        
        if !self.areControlsHidden {
            self.statusBar?.alpha = transition
            self.navigationBar?.alpha = transition
            self.footerNode.alpha = transition
        }
        
        if let toolbarNode = toolbarNode {
            toolbarNode.layer.position = CGPoint(x: toolbarNode.layer.position.x, y: self.bounds.size.height - toolbarNode.bounds.size.height / 2.0 + (1.0 - transition) * toolbarNode.bounds.size.height)
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        targetContentOffset.pointee = scrollView.contentOffset
        
        if abs(velocity.y) > 1.0 {
            if let backgroundColor = self.backgroundNode.backgroundColor {
                self.backgroundNode.layer.animate(from: backgroundColor, to: UIColor(white: 0.0, alpha: 0.0).cgColor, keyPath: "backgroundColor", timingFunction: kCAMediaTimingFunctionLinear, duration: 0.2, removeOnCompletion: false)
            }
            
            var interfaceAnimationCompleted = false
            var contentAnimationCompleted = true
            
            let completion = { [weak self] in
                if interfaceAnimationCompleted && contentAnimationCompleted {
                    if let dismiss = self?.dismiss {
                        dismiss()
                    }
                }
            }
            
            if let centralItemNode = self.pager.centralItemNode(), let transitionNodeForCentralItem = self.transitionNodeForCentralItem, let node = transitionNodeForCentralItem() {
                contentAnimationCompleted = false
                centralItemNode.animateOut(to: node, completion: {
                    contentAnimationCompleted = true
                    completion()
                })
            }
            
            self.animateOut(animateContent: false, completion: {
                interfaceAnimationCompleted = true
                completion()
            })
            
            if contentAnimationCompleted {
                contentAnimationCompleted = false
                self.scrollView.layer.animateBounds(from: self.scrollView.layer.bounds, to: self.scrollView.layer.bounds.offsetBy(dx: 0.0, dy: self.scrollView.layer.bounds.size.height * (velocity.y < 0.0 ? -1.0 : 1.0)), duration: 0.2, timingFunction: kCAMediaTimingFunctionLinear, removeOnCompletion: false, completion: { _ in
                    contentAnimationCompleted = true
                    completion()
                })
            }
        } else {
            self.scrollView.setContentOffset(CGPoint(x: 0.0, y: self.scrollView.contentSize.height / 3.0), animated: true)
        }
    }
    
    func updatePresentationState(_ f: (GalleryControllerPresentationState) -> GalleryControllerPresentationState, transition: ContainedViewLayoutTransition) {
        self.presentationState = f(self.presentationState)
        if let (navigationBarHeight, layout) = self.containerLayout {
            self.containerLayoutUpdated(layout, navigationBarHeight: navigationBarHeight, transition: transition)
        }
    }
}
