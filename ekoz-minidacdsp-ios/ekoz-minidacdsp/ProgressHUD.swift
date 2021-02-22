//
//  ProgressHUD.swift
//  ekoz-minidacdsp
//
//  Created on 04/02/2021.
//
//  ekoz-minidacdsp by Dimitri Fontaine is licensed under CC BY-NC 4.0.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/4.0/
//

import Foundation
import UIKit

public class ProgressHUD {
    
    private let containerBackView = UIView()
    private let containerView = UIView()
    private let containerView2 = UIView()
    
    private let hudColor = UIColor(red: 153/255, green: 153/255, blue: 150/255, alpha: 1)
    private let hudColor2 = UIColor(red: 153/255, green: 153/255, blue: 150/255, alpha: 0.3)
    private var duration: CFTimeInterval = 0.75
    
    private let shapeLayer = CAShapeLayer()
    private let shapeLayer2 = CAShapeLayer()
    
    private let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
    private let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
    private let scaleAnimation2 = CABasicAnimation(keyPath: "transform.scale")
    
    private func createHUD(view: UIView) {
        
        containerBackView.frame = view.frame
        containerBackView.backgroundColor = UIColor.init(white: 0, alpha: 0.5)
        
        
        containerView.frame = CGRect(x: 0, y: 0, width: 150, height: 150)
        containerView.backgroundColor = .clear
        containerView.center = CGPoint(x: view.bounds.midX, y: view.bounds.maxY * 3 / 7)
        shapeLayer.path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 150, height: 150)).cgPath
        shapeLayer.strokeColor = hudColor.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = 10
        shapeLayer.strokeEnd = 0.65
        shapeLayer.lineCap = .square
        
        containerView.layer.addSublayer(shapeLayer)
        
        rotationAnimation.fromValue = 0
        rotationAnimation.duration = duration
        rotationAnimation.toValue = CGFloat(Double.pi * 2)
        rotationAnimation.repeatCount = .infinity
        containerView.layer.add(rotationAnimation, forKey: nil)
        
        //-----------
        
        
        containerView2.frame = CGRect(x: 0, y: 0, width: 150, height: 150)
        containerView2.backgroundColor = .clear
        containerView2.center = CGPoint(x: view.bounds.midX, y: view.bounds.maxY * 3 / 7)
        shapeLayer2.path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 150, height: 150)).cgPath
        shapeLayer2.strokeColor = hudColor2.cgColor
        shapeLayer2.fillColor = UIColor.clear.cgColor
        shapeLayer2.lineWidth = 10
        shapeLayer2.strokeEnd = 1
        shapeLayer2.lineCap = .square
        
        containerView2.layer.addSublayer(shapeLayer2)
        
        
        
    }
    
    
    public func show(in view: UIView) {
        view.addSubview(containerBackView)
        view.addSubview(containerView)
        view.addSubview(containerView2)
        createHUD(view: view)
    }
    
    public func hide() {
        DispatchQueue.main.async {
            self.containerBackView.removeFromSuperview()
            self.containerView.removeFromSuperview()
            self.containerView2.removeFromSuperview()
        }
        
    }
    
    
}

