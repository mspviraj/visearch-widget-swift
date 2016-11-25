//
//  ViColorSearchViewController.swift
//  ViSearchWidgets
//
//  Created by Hung on 25/11/16.
//  Copyright © 2016 Visenze. All rights reserved.
//

import UIKit
import ViSearchSDK
import LayoutKit

open class ViColorSearchViewController: ViGridSearchViewController , UIPopoverPresentationControllerDelegate, ViColorPickerDelegate {

    // default list of colors
    open var colorList: [String] = [
        "000000" , "555555" , "9896a4" ,
        "034f84" , "00afec" , "98ddde" ,
        "00ffff" , "f5977d" , "91a8d0",
        "ea148c" , "f53321" , "d66565" ,
        "ff00ff" , "a665a7" , "e0b0ff" ,
        "f773bd" , "f77866" , "7a2f04" ,
        "cc9c33" , "618fca" , "79c753" ,
        "228622" , "4987ec" , "2abab3"
    ]
    
    open override func setup(){
        super.setup()
        self.title = "Search By Color"
        // hide this as we will use the query color picker
        self.showTitleHeader = false
    }
    
    /// layout for header that contains query product and filter
    open override var headerLayout : Layout? {
        var allLayouts : [Layout] = []
        
        var colorLogoLayouts : [Layout] = []
        
        // add color preview
        let colorPreviewLayout = SizeLayout<UIView>(
                                         width: 120,
                                         height: 120,
                                         alignment: .topLeading,
                                         flexibility: .inflexible,
                                         config: { v in
                                            
                                            if let colorParams = self.searchParams as? ViColorSearchParams {
                                                v.backgroundColor = UIColor.colorWithHexString(colorParams.color, alpha: 1.0)
                                            }
                                         }
        )
        
        // wrap color preview and color picker icon
        let colorPickerEl = SizeLayout<UIButton>(
            width: ViIcon.color_pick!.width + 8, height: ViIcon.color_pick!.height + 8,
            alignment: .bottomTrailing ,
            flexibility: .inflexible,
            viewReuseId: nil,
            config: { button in
                
                button.backgroundColor = ViTheme.sharedInstance.color_pick_btn_background_color
                
                button.setImage(ViIcon.color_pick, for: .normal)
                button.setImage(ViIcon.color_pick, for: .highlighted)
                
                button.tintColor = ViTheme.sharedInstance.color_pick_btn_tint_color
                button.imageEdgeInsets = UIEdgeInsetsMake( 4, 4, 4, 4)
                button.tag = ViProductCardTag.colorPickBtnTag.rawValue
                
                button.addTarget(self, action: #selector(self.openColorPicker), for: .touchUpInside)
                
            }
            
        )
        
        let colorPreviewAndPickerLayout = StackLayout(
            axis: .horizontal,
            spacing: 2,
            sublayouts: [colorPreviewLayout , colorPickerEl]
        )
        
        colorLogoLayouts.append(colorPreviewAndPickerLayout)
        
    
        if showPowerByViSenze {
            let powerByLayout = self.getPowerByVisenzeLayout()
            colorLogoLayouts.append(powerByLayout)
        }
        
        // add in the border view at bottom
        let divider = self.getDividerLayout()
        colorLogoLayouts.append(divider)
        
        let productAndLogoStackLayout = StackLayout(
            axis: .vertical,
            spacing: 2,
            sublayouts: colorLogoLayouts
        )
        
        allLayouts.append(productAndLogoStackLayout)
        
        
        // label and filter layout
        let labelAndFilterLayout = self.getLabelAndFilterLayout(emptyProductsTxt: "Products Found", displayStringFormat: "%d Products Found")
        allLayouts.append(labelAndFilterLayout)
        
        let allStackLayout = StackLayout(
            axis: .vertical,
            spacing: 4,
            sublayouts: allLayouts
        )
        
        let insetLayout =  InsetLayout(
            insets: EdgeInsets(top: 8, left: 8, bottom: 8, right: 8),
            sublayout: allStackLayout
        )
        
        
        return insetLayout
        
    }
    
    public func openColorPicker(sender: UIButton, forEvent event: UIEvent) {
        let controller = ViColorPickerModalViewController()
        controller.modalPresentationStyle = .popover
        controller.delegate = self
        controller.colorList = self.colorList
        controller.paddingLeft = 8
        controller.paddingRight = 8
        controller.preferredContentSize = CGSize(width: self.view.bounds.width, height: 300)
        
        if let popoverController = controller.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = sender.frame
            popoverController.permittedArrowDirections = UIPopoverArrowDirection.any
            popoverController.delegate = self 
            
        }
        
        
        self.present(controller, animated: true, completion: nil)
    }
    
    // important - this is needed so that a popover will be shown instead of fullscreen
    public func adaptivePresentationStyle(for controller: UIPresentationController,
                                            traitCollection: UITraitCollection) -> UIModalPresentationStyle{
        return .none
    }
    
    // MARK: ViColorPickerDelegate
    public func didPickColor(sender: ViColorPickerModalViewController, color: String) {
        // set the color params 
        if let colorParams = self.searchParams as? ViColorSearchParams {
            colorParams.color = color
            
            sender.dismiss(animated: true, completion: nil)
            
            // update preview box and refresh data
            self.refreshData()
        }
    }

    
    /// since we show the logo below the color preview box it is not necessary to show again
    open override var footerSize : CGSize {
        return CGSize.zero
    }

    /// call ViSearch API and refresh the views
    open override func refreshData() {
        
        if( searchParams != nil && (searchParams is ViColorSearchParams) ) {
            
            if let searchParams = searchParams {
                
                // construct the fl based on schema mappings
                // need to merge the array to make sure that the returned data contain the relevant meta data in mapping
                let metaArr = self.schemaMapping.getMetaArrForSearch()
                let combinedArr = searchParams.fl + metaArr
                let flSet = Set(combinedArr)
                searchParams.fl = Array(flSet)
                
                ViSearch.sharedInstance.colorSearch(
                    params: searchParams as! ViColorSearchParams,
                    successHandler: {
                        (data : ViResponseData?) -> Void in
                        // check ViResponseData.hasError and ViResponseData.error for any errors return by ViSenze server
                        if let data = data {
                            if data.hasError {
                                let errMsgs =  data.error.joined(separator: ",")
                                print("API error: \(errMsgs)")
                                
                                // TODO: display system busy message here
                                self.delegate?.searchFailed(err: nil, apiErrors: data.error)
                            }
                            else {
                                
                                // display and refresh here
                                self.reqId = data.reqId
                                self.products = ViSchemaHelper.parseProducts(mapping: self.schemaMapping, data: data)
                                
                                
                                self.delegate?.searchSuccess(searchType: ViSearchType.FIND_SIMILAR , reqId: data.reqId, products: self.products)
                                
                                DispatchQueue.main.async {
                                    self.collectionView?.reloadData()
                                }
                                
                            }
                        }
                        
                },
                    failureHandler: {
                        (err) -> Void in
                        // Do something when request fails e.g. due to network error
                        // print ("error: \\(err.localizedDescription)")
                        // TODO: display error message and tap to try again
                        self.delegate?.searchFailed(err: err, apiErrors: [])
                        
                })
            }
        }
        else {
            
            print("\(type(of: self)).\(#function)[line:\(#line)] - error: Search parameter must be ViColorSearchParams type and is not nil.")
            
            
        }
    }
    
}
