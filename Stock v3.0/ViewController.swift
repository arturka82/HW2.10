//
//  ViewController.swift
//  Stock v3.0
//
//  Created by Artur Gedakyan on 29.08.2020.
//  Copyright © 2020 Artur Gedakyan. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var companyPickerView: UIPickerView!
    @IBOutlet weak var companyNameLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var companySymbolLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var priceChangeLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    // MARK: - Private variables
    
    private lazy var companies = [
        "Apple": "AAPL" ,
        "Microsoft": "MSFT" ,
        "Google": "GOOG" ,
        "Amazon": "AMZN" ,
        "Facebook": "FB" ,
    ]
    
    // MARK: - Ovveride functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        companyNameLabel.text = "Tinkoff"
        companyPickerView.dataSource = self
        companyPickerView.delegate = self
        
        activityIndicator.hidesWhenStopped = true
        activityIndicator.stopAnimating()
        requestQuoteUpdate()
    }
    
}

// MARK: - Private functions

private extension ViewController {
    
    func requestQuoteUpdate() {
        activityIndicator.startAnimating()
        companyNameLabel.text = "-"
        companySymbolLabel.text = "-"
        priceLabel.text = "-"
        priceChangeLabel.text = "-"
        
        let selectedRow = companyPickerView.selectedRow(inComponent: 0)
        let selectedSymbol = Array(companies.values)[selectedRow]
        requestQuote(for: selectedSymbol)
        downloadLogo(for: selectedSymbol)
    }
    
    func requestQuote(for symbol: String) {
        let token = "sk_878c646a8ee148129639531a058d516b"
        
        guard let url = URL(string: "https://cloud.iexapis.com/stable/stock/\(symbol)/quote?token=\(token)") else {
            return
        }
        
        let dataTask = URLSession.shared.dataTask(with: url) { [weak self] (data , response, error) in
            if let data = data,
                (response as? HTTPURLResponse)?.statusCode == 200,
                error == nil {
                self?.parseQuote(from: data)
            } else {
                self?.showErrorAlert()
            }
        }
        dataTask.resume()
    }
    
    func parseQuote(from data: Data) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            guard
                let json = jsonObject as? [String: Any],
                let companyName = json["companyName"] as? String,
                let companySymbol = json["symbol"] as? String,
                let price = json["latestPrice"] as? Double,
                let priceChange = json["change"] as? Double
                else {
                    return print("Invalid")
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.displayStockInfo(companyName: companyName,
                                       companySymbol: companySymbol,
                                       price: price,
                                       priceChange: priceChange)
            }
        } catch {
            showErrorAlert()
        }
    }
    
    func displayStockInfo(companyName: String,
                          companySymbol: String,
                          price: Double,
                          priceChange: Double) {
        activityIndicator.stopAnimating()
        companyNameLabel.text = companyName
        companySymbolLabel.text = companySymbol
        priceLabel.text = "\(price) $"
        priceChangeLabel.text = "\(priceChange)"
        
        if priceChange > 0 {
            priceChangeLabel.textColor = .green
        } else if priceChange < 0 {
            priceChangeLabel.textColor = .red
        } else {
            priceChangeLabel.textColor = .black
        }
    }
    
    func downloadLogo(for symbol: String) {
        guard let url = URL(string: "https://storage.googleapis.com/iex/api/logos/\(symbol).png") else {
            return
        }
        
        let dataTask = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            if let data = data,
                (response as? HTTPURLResponse)?.statusCode == 200,
                error == nil {
                DispatchQueue.main.async {
                    self?.imageView.image = UIImage(data: data)
                }
            } else {
                self?.showErrorAlert()
            }
        }
        dataTask.resume()
    }
    
    func showErrorAlert() {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Error", message: "Not internet connection", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            self.present(alert, animated: true)
        }
    }
    
}

// MARK: - UIPickerViewDataSource

extension ViewController: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView( _ pickerView: UIPickerView,numberOfRowsInComponent component: Int) -> Int {
        return companies.keys.count
    }
    
}

// MARK: - UIPickerViewDelegate

extension ViewController: UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Array(companies.keys)[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        requestQuoteUpdate()
    }
    
}
