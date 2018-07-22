//
//  MGSegmentedProgressBar.swift
//  MGSegmentedProgressBar
//
//  Created by Mac Gallagher on 6/15/18.
//  Copyright © 2018 Mac Gallagher. All rights reserved.
//

import UIKit

public enum MGLineCap {
    case round, butt, square
}

open class MGSegmentedProgressBar: UIView {
    
    public var dataSource: MGSegmentedProgressBarDataSource? {
        didSet { reloadData() }
    }
    
    private let trackView: UIView = {
        let track = UIView()
        track.clipsToBounds = true
        return track
    }()
    
    private var trackViewConstriants = [NSLayoutConstraint]()
    
    public var trackInset: CGFloat = 0 {
        didSet { layoutTrackView() }
    }
    
    public var trackBackgroundColor: UIColor? {
        didSet {
            trackView.backgroundColor = trackBackgroundColor
        }
    }
    
    public private(set) var titleLabel: UILabel?
    private var labelConstraints = [NSLayoutConstraint]()
    
    public var labelEdgeInsets: UIEdgeInsets = .zero {
        didSet { setNeedsLayout() }
    }

    public var labelAlignment: MGLabelAlignment = .center {
        didSet { setNeedsLayout() }
    }
    
    public var lineCap: MGLineCap = .round {
        didSet { setNeedsDisplay() }
    }
    
    private var numberOfSections: Int = 0
    private var bars: [MGBarView] = []
    private var barWidthConstraints: [NSLayoutConstraint] = []
    
    private var currentSteps: [Int] = []
    private var currentStepsTotal: Int {
        return currentSteps.reduce(0, { $0 + $1 })
    }
    private var totalSteps: Int = 0
    
    //MARK: - Initialization (DONE)
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    private func sharedInit() {
        clipsToBounds = true
        addSubview(trackView)
    }
    
    //MARK: - Layout (DONE)

    open override func layoutSubviews() {
        super.layoutSubviews()
        layoutTrackView()
        layoutTrackTitleLabel()
        for (section, bar) in bars.enumerated() {
            layoutBar(bar, section: section)
        }
    }
    
    private func layoutTrackView() {
        NSLayoutConstraint.deactivate(trackViewConstriants)
        if lineCap == .butt {
            trackViewConstriants = trackView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, topConstant: trackInset, bottomConstant: trackInset)
        } else {
            trackViewConstriants = trackView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, topConstant: trackInset, leftConstant: trackInset, bottomConstant: trackInset, rightConstant: trackInset)
        }
    }
    
    private func layoutTrackTitleLabel() {
        guard let titleLabel = titleLabel else { return }
        
        NSLayoutConstraint.deactivate(labelConstraints)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        labelConstraints = []
        
        switch labelAlignment {
        case .left:
            labelConstraints.append(titleLabel.leftAnchor.constraint(equalTo: layoutMarginsGuide.leftAnchor))
            labelConstraints.append(titleLabel.centerYAnchor.constraint(equalTo: layoutMarginsGuide.centerYAnchor))
        case .topLeft:
            labelConstraints.append(titleLabel.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor))
            labelConstraints.append(titleLabel.leftAnchor.constraint(equalTo: layoutMarginsGuide.leftAnchor))
        case .top:
            labelConstraints.append(titleLabel.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor))
            labelConstraints.append(titleLabel.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor))
        case .topRight:
            labelConstraints.append(titleLabel.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor))
            labelConstraints.append(titleLabel.rightAnchor.constraint(equalTo: layoutMarginsGuide.rightAnchor))
        case .right:
            labelConstraints.append(titleLabel.rightAnchor.constraint(equalTo: layoutMarginsGuide.rightAnchor))
            labelConstraints.append(titleLabel.centerYAnchor.constraint(equalTo: layoutMarginsGuide.centerYAnchor))
        case .bottomRight:
            labelConstraints.append(titleLabel.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor))
            labelConstraints.append(titleLabel.rightAnchor.constraint(equalTo: layoutMarginsGuide.rightAnchor))
        case .bottom:
            labelConstraints.append(titleLabel.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor))
            labelConstraints.append(titleLabel.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor))
        case .bottomLeft:
            labelConstraints.append(titleLabel.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor))
            labelConstraints.append(titleLabel.leftAnchor.constraint(equalTo: layoutMarginsGuide.leftAnchor))
        case .center:
            labelConstraints.append(titleLabel.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor))
            labelConstraints.append(titleLabel.centerYAnchor.constraint(equalTo: layoutMarginsGuide.centerYAnchor))
        }
        
        NSLayoutConstraint.activate(labelConstraints)
    }
    
    private func layoutBar(_ bar: MGBarView, section: Int) {
        NSLayoutConstraint.deactivate([barWidthConstraints[section]])
        if totalSteps != 0 {
            let widthMultiplier = CGFloat(currentSteps[section]) / CGFloat(totalSteps)
            barWidthConstraints[section] = bar.widthAnchor.constraint(equalTo: trackView.widthAnchor, multiplier: widthMultiplier)
        }
        NSLayoutConstraint.activate([barWidthConstraints[section]])
    }
    
    open override func draw(_ rect: CGRect) {
        super.draw(rect)
        switch lineCap {
        case .round:
            layer.cornerRadius = bounds.height / 2
            trackView.layer.cornerRadius = trackView.bounds.height / 2
        case .butt, .square:
            layer.cornerRadius = 0
            trackView.layer.cornerRadius = 0
        }
    }
    
    //MARK: - Data Source (DONE)
    
    public func reloadData() {
        guard let dataSource = dataSource else { return }
        
        bars.forEach({ $0.removeFromSuperview() })
        bars = []
        currentSteps = []
        barWidthConstraints = []
        numberOfSections = dataSource.numberOfSections(in: self)
        totalSteps = dataSource.numberOfSteps(in: self)
        
        for section in 0..<numberOfSections {
            let bar = reloadBar(section: section) ?? MGBarView()
            bars.append(bar)
            currentSteps.append(0)
            trackView.addSubview(bar)
            barWidthConstraints.append(NSLayoutConstraint())
            if section == 0 {
                _ = bar.anchor(top: trackView.topAnchor, left: trackView.leftAnchor, bottom: trackView.bottomAnchor)
            } else {
                _ = bar.anchor(top: trackView.topAnchor, left: bars[section - 1].rightAnchor, bottom: trackView.bottomAnchor)
            }
        }
    }
    
    private func reloadBar(section: Int) -> MGBarView? {
        guard let dataSource = dataSource else { return nil }
        let bar = dataSource.progressBar(self, barForSection: section)
        
        let attributedTitle = dataSource.progressBar(self, attributedTitleForSection: section)
        bar.setAttributedTitle(attributedTitle)
        
        let title = dataSource.progressBar(self, titleForSection: section)
        bar.setTitle(title)
        
        let insets = dataSource.progressBar(self, titleInsetsForSection: section)
        bar.labelEdgeInsets = insets
        
        let alignment = dataSource.progressBar(self, titleAlignmentForSection: section)
        bar.labelAlignment = alignment
        
        return bar
    }
    
    //MARK: - Setters/Getters (DONE)
    
    public func setTitle(_ title: String?) {
        if titleLabel == nil {
            titleLabel = UILabel()
            trackView.insertSubview(titleLabel!, at: 0)
        }
        titleLabel?.text = title
        layoutTrackTitleLabel()
    }
    
    public func setAttributedTitle(_ title: NSAttributedString?) {
        if titleLabel == nil {
            titleLabel = UILabel()
            trackView.insertSubview(titleLabel!, at: 0)
        }
        titleLabel?.attributedText = title
        layoutTrackTitleLabel()
    }
    
    //MARK: - Main Methods (DONE)
    
    open func setProgress(section: Int, steps: Int) {
        if section < 0 || section >= numberOfSections { return }
        let newCurrentSteps = (currentStepsTotal - currentSteps[section] + steps)
        currentSteps[section] = max(0, steps + min(0, totalSteps - newCurrentSteps))
        layoutBar(bars[section], section: section)
        layoutIfNeeded()
    }
    
    open func advance(section: Int, by numberOfSteps: Int = 1) {
        setProgress(section: section, steps: currentSteps[section] + numberOfSteps)
    }

    open func resetProgress() {
        for section in 0..<bars.count {
            setProgress(section: section, steps: 0)
        }
    }

    
}







