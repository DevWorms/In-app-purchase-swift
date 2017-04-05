//
//  ViewController.swift
//  InAppPurchase
//
//  Created by Brian Coleman on 2015-05-19.
//  Copyright (c) 2015 Brian Coleman. All rights reserved.
//

import UIKit
import StoreKit
import Alamofire
class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SKProductsRequestDelegate, SKPaymentTransactionObserver {
   
    
    let producto = "CocinaMexicanaRecetasFaciles"

    var tableView = UITableView()
    let productIdentifiers = Set(["CocinaMexicanaRecetasFaciles"])
    var product: SKProduct?
    var productsArray = Array<SKProduct>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        tableView = UITableView(frame: self.view.frame)
        
        tableView.separatorColor = UIColor.clear
        
        tableView.dataSource = self
        tableView.delegate = self
        
        self.view.addSubview(tableView)
        
        SKPaymentQueue.default().add(self)
        requestProductData()
        
      //  SKPaymentQueue.default().restoreCompletedTransactions()
        
        self.verificarSubs()
    }
    
    func verificarSubs(){
        
        

        //NSDictionary *dictLatestReceiptsInfo = response[@"latest_receipt_info"];
        //long expirationDateMs = [dictLatestReceiptsInfo valueForKeyPath:@"@max.expires_date_ms"];
        
        let receiptURL = Bundle.main.appStoreReceiptURL
        let receipt = NSData(contentsOf: receiptURL!)
        let requestContents: [String: Any] = [
            "receipt-data": receipt!.base64EncodedString(options: []),
            "password": "b7f13ceae7454c23aba22b373352337b"
        ]
        
        let appleServer = receiptURL?.lastPathComponent == "sandboxReceipt" ? "sandbox" : "buy"
        
        let stringURL = "https://\(appleServer).itunes.apple.com/verifyReceipt"
        
        print("Loading user receipt: \(stringURL)...")
        
        _ = Alamofire.request(stringURL, method: .post, parameters: requestContents, encoding: JSONEncoding.default)
            .responseJSON { response in
                if let value = response.result.value as? NSDictionary {
                 //  print(value)
                    
                    if let json = value["latest_receipt_info"] {
                    
                        
                        var jsonStr = String(describing:json)
                        jsonStr.remove(at: jsonStr.index(before: jsonStr.endIndex))
                        jsonStr.remove(at: jsonStr.startIndex)
                        jsonStr = jsonStr.replacingOccurrences(of: ";", with: ",")
                        jsonStr = jsonStr.replacingOccurrences(of: "=", with: ":")
                        jsonStr = jsonStr.replacingOccurrences(of: "quantity", with: "\"quantity\"")
                        jsonStr = jsonStr.replacingOccurrences(of: self.producto, with: "\""+self.producto+"\"")
                        jsonStr = jsonStr.replacingOccurrences(of: ",\n    }", with: "\n    }")
                        jsonStr = " [ "+jsonStr+" ] "
                        print(jsonStr)
                        
                        
                        if let data = jsonStr.data(using: .utf8) {
                            do {
                                if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]]{
                                    print(jsonArray.count)
                                    let ultimaSubscripcion = jsonArray.last
                                    if var dateString = ultimaSubscripcion?["expires_date"] as? String{
                                        dateString = dateString.replacingOccurrences(of: "Etc/GMT", with: "")
                                        print(dateString)
                                    
                                        let dateFormatter = DateFormatter()
                                        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss" //Your date format
                                        dateFormatter.timeZone = NSTimeZone(abbreviation: "GMT") as TimeZone!
                                        
                                        let date = dateFormatter.date(from: dateString) //according to date format your date string
                                        
                                        let fechaActual =  NSDate()
                                        
                                        print(date ?? "", fechaActual) //Convert String to Date
                                        
                                        if date! < fechaActual as Date{
                                            print("suscripcion esta expirada")
                                        }
                                        else{
                                            print("suscripcion activa")
                                        }
                                    
                                    }
                                    
                                }
 
                                
                            } catch {
                                print(error.localizedDescription)
                            }
                        }

                        
                    }
                } else {
                    print("Receiving receipt from App Store failed: \(response.result)")
                }
        }
        
      
        
        // let currentTime = NSDate().timeIntervalSince1970 let expired = currentTime > expiresTime
    }
    
    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }

    
    override func viewWillDisappear(_ animated: Bool) {
        SKPaymentQueue.default().remove(self)
    }
    
    // In-App Purchase Methods
    
    func requestProductData()
    {
        if SKPaymentQueue.canMakePayments() {
            let request = SKProductsRequest(productIdentifiers:
                self.productIdentifiers as Set<String>)
            request.delegate = self
            request.start()
        } else {
            var alert = UIAlertController(title: "In-App Purchases Not Enabled", message: "Please enable In App Purchase in Settings", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Settings", style: UIAlertActionStyle.default, handler: { alertAction in
                alert.dismiss(animated: true, completion: nil)
                
                let url: URL? = URL(string: UIApplicationOpenSettingsURLString)
                if url != nil
                {
                    UIApplication.shared.openURL(url!)
                }
                
            }))
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: { alertAction in
                alert.dismiss(animated: true, completion: nil)
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func productsRequest(_ request: SKProductsRequest!, didReceive response: SKProductsResponse!) {
        
        var products = response.products
        
        if (products.count != 0) {
            for i in 0 ..< products.count
            {
                self.product = products[i] as? SKProduct
                self.productsArray.append(product!)
            }
            self.tableView.reloadData()
        } else {
            print("No products found")
        }
        print(response.description)
        let productos = response.invalidProductIdentifiers
        
        for product in 0 ..< products.count
        {
            print("Product not found: \(product)")
        }
    }
    
    func buyProduct(_ sender: UIButton) {
        let payment = SKPayment(product: productsArray[sender.tag])
        SKPaymentQueue.default().add(payment)
    }
    
    
    @available(iOS 3.0, *)
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        
        for transaction in transactions as! [SKPaymentTransaction] {
            
            switch transaction.transactionState {
                
            case SKPaymentTransactionState.purchased:
                print("Transaction Approved")
                print("Product Identifier: \(transaction.payment.productIdentifier)")
                self.deliverProduct(transaction)
                SKPaymentQueue.default().finishTransaction(transaction)
                
            case SKPaymentTransactionState.failed:
                print("Transaction Failed")
                SKPaymentQueue.default().finishTransaction(transaction)
            default:
                break
            }
        }
    }

    func deliverProduct(_ transaction:SKPaymentTransaction) {
        
        if transaction.payment.productIdentifier == "com.brianjcoleman.testiap1"
        {
            print("Consumable Product Purchased")
            // Unlock Feature
        }
        else if transaction.payment.productIdentifier == "com.brianjcoleman.testiap2"
        {
            print("Non-Consumable Product Purchased")
            // Unlock Feature
        }
        else if transaction.payment.productIdentifier == "CocinaMexicanaRecetasFaciles"
        {
            print("Auto-Renewable Subscription Product Purchased")
            // Unlock Feature
        }
        else if transaction.payment.productIdentifier == "com.brianjcoleman.testiap4"
        {
            print("Free Subscription Product Purchased")
            // Unlock Feature
        }
        else if transaction.payment.productIdentifier == "com.brianjcoleman.testiap5"
        {
            print("Non-Renewing Subscription Product Purchased")
            // Unlock Feature
        }
    }
    
    func restorePurchases(_ sender: UIButton) {
        SKPaymentQueue.default().add(self)
        SKPaymentQueue.default().restoreCompletedTransactions()
    }

    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue!) {
        print("Transactions Restored")
        
       // var purchasedItemIDS = Array()
        for transaction:SKPaymentTransaction in queue.transactions {
           
            if transaction.payment.productIdentifier == "com.brianjcoleman.testiap1"
            {
                print("Consumable Product Purchased")
                // Unlock Feature
            }
            else if transaction.payment.productIdentifier == "com.brianjcoleman.testiap2"
            {
                print("Non-Consumable Product Purchased")
                // Unlock Feature
            }
            else if transaction.payment.productIdentifier == "CocinaMexicanaRecetasFaciles"
            {
                print("Auto-Renewable Subscription Product Purchased")
                // Unlock Feature
                
                
                //print(transaction.payment.rec)
            }
            else if transaction.payment.productIdentifier == "com.brianjcoleman.testiap4"
            {
                print("Free Subscription Product Purchased")
                // Unlock Feature
            }
            else if transaction.payment.productIdentifier == "com.brianjcoleman.testiap5"
            {
                print("Non-Renewing Subscription Product Purchased")
                // Unlock Feature
            }
            
            
        }
        
        var alert = UIAlertView(title: "Thank You", message: "Your purchase(s) were restored.", delegate: nil, cancelButtonTitle: "OK")
        alert.show()
    }
    
    // Screen Layout Methods
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.productsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cellFrame = CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 52.0)
        let retCell = UITableViewCell(frame: cellFrame)
        
        if self.productsArray.count != 0
        {
            if indexPath.row == 5
            {
                let restoreButton = UIButton(frame: CGRect(x: 10.0, y: 10.0, width: UIScreen.main.bounds.width - 20.0, height: 44.0))
                restoreButton.titleLabel!.font = UIFont (name: "HelveticaNeue-Bold", size: 20)
                restoreButton.addTarget(self, action: #selector(ViewController.restorePurchases(_:)), for: UIControlEvents.touchUpInside)
                restoreButton.backgroundColor = UIColor.black
                restoreButton.setTitle("Restore Purchases", for: UIControlState())
                retCell.addSubview(restoreButton)
            }
            else
            {
                let singleProduct = productsArray[indexPath.row]
                
                let titleLabel = UILabel(frame: CGRect(x: 10.0, y: 0.0, width: UIScreen.main.bounds.width - 20.0, height: 25.0))
                titleLabel.textColor = UIColor.black
                titleLabel.text = singleProduct.localizedTitle
                titleLabel.font = UIFont (name: "HelveticaNeue", size: 20)
                retCell.addSubview(titleLabel)

                let descriptionLabel = UILabel(frame: CGRect(x: 10.0, y: 10.0, width: UIScreen.main.bounds.width - 70.0, height: 40.0))
                descriptionLabel.textColor = UIColor.black
                descriptionLabel.text = singleProduct.localizedDescription
                descriptionLabel.font = UIFont (name: "HelveticaNeue", size: 12)
                retCell.addSubview(descriptionLabel)
                
                let buyButton = UIButton(frame: CGRect(x: UIScreen.main.bounds.width - 60.0, y: 5.0, width: 50.0, height: 20.0))
                buyButton.titleLabel!.font = UIFont (name: "HelveticaNeue", size: 12)
                buyButton.tag = indexPath.row
                buyButton.addTarget(self, action: #selector(ViewController.buyProduct(_:)), for: UIControlEvents.touchUpInside)
                buyButton.backgroundColor = UIColor.black
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = .currency
                numberFormatter.locale = Locale.current
                buyButton.setTitle(numberFormatter.string(from: singleProduct.price), for: UIControlState())
                retCell.addSubview(buyButton)
            }
        }
        
        return retCell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 52.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        if section == 0
        {	return 64.0
        }
        
        return 32.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        let ret = UILabel(frame: CGRect(x: 10, y: 0, width: self.tableView.frame.width - 20, height: 32.0))
        ret.backgroundColor = UIColor.clear
        ret.text = "In-App Purchases"
        ret.textAlignment = NSTextAlignment.center
        return ret
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

