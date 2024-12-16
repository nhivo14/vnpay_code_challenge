//
//  HomeViewController.swift
//  Code-Challenge
//
//  Created by Nhi on 12/15/24.
//

import UIKit

class HomeViewController: UIViewController {

    @IBOutlet weak var searchView: CommonSearchView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    private let refreshControl = UIRefreshControl()
    private let viewModel = HomeViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupUI()
        setupSearchView()
        setupBinding()
        viewModel.fetchData()
    }
    
    private func setupUI() {
        tableView.register(UINib(nibName: "ImageItemTableViewCell", bundle: nil), forCellReuseIdentifier: "ImageItemTableViewCell")
        tableView.delegate = self
        tableView.dataSource = self
        
        refreshControl.addTarget(self, action: #selector(handlePullToRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        indicator.isHidden = true
        
    }
    
    private func setupSearchView() {
        self.searchView.setTextfieldDelegate(self)
        self.searchView.applySwipeTyping()
        
        self.searchView.handleTextDidChange = { [weak self] text in
            guard let self else { return }
            let pattern = "^[a-zA-Z0-9!@#$%^&*():.,<>/\\[\\]?]+$"
            let regex = try? NSRegularExpression(pattern: pattern)
            let range = NSRange(location: 0, length: text.utf16.count)
            
            if regex?.firstMatch(in: text, range: range) == nil {
                let newString = text.folding(options: .diacriticInsensitive, locale: .current)
                self.searchView.updateTextSearch(newString)
            }
            // search
            self.viewModel.search(text)
        }
    }
    
    
    @objc
    private func handlePullToRefresh() {
        viewModel.pullToRefresh()
    }
    
    private func setupBinding() {
        viewModel.onDataUpdated = { [weak self] in
            DispatchQueue.main.async {
                self?.indicator.stopAnimating()
                self?.indicator.isHidden = true
                self?.tableView.reloadData()
                self?.refreshControl.endRefreshing()
            }
        }
        
        viewModel.onError = { [weak self] error in
            // should show dialog about error
            print("da co loi: \(error)")
            self?.indicator.stopAnimating()
            self?.indicator.isHidden = true
            self?.refreshControl.endRefreshing()
        }
        
        viewModel.onUpdateIndicator = { [weak self] isLoading in
            DispatchQueue.main.async {
                if isLoading {
                    self?.indicator.startAnimating()
                    self?.indicator.isHidden = false
                } else {
                    self?.indicator.stopAnimating()
                    self?.indicator.isHidden = true
                }
            }
        }
    }
}

@available(iOS 13.0, *)
extension HomeViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.itemCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ImageItemTableViewCell", for: indexPath) as! ImageItemTableViewCell
        if let data = viewModel.getItem(at: indexPath.row), let url = URL(string: data.downloadURL ?? "") {
            if let cachedImage = ImageDownloadManager.shared.getCachedImage(with: data.downloadURL ?? "") {
                cell.configCell(with: data, image: cachedImage)
            } else {
                cell.configCell(with: data)
                ImageDownloadManager.shared.downloadImage(with: url) { uiImage in
                    DispatchQueue.main.async {
                        cell.configureImage(with: uiImage)
                    }
                }
            }
        }
        return cell
    }
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let data = viewModel.getItem(at: indexPath.row), let url = URL(string: data.downloadURL ?? "") {
            ImageDownloadManager.shared.pauseDownload(for: url)
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let data = viewModel.getItem(at: indexPath.row), let url = URL(string: data.downloadURL ?? "") {
            ImageDownloadManager.shared.resumeDownload(for: url)
        }
        
        if indexPath.row == viewModel.itemCount - 1, self.viewModel.getSearchText() == "" {
            viewModel.loadMore()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let data = viewModel.getItem(at: indexPath.row) {
            let width = CGFloat(data.width ?? 0)
            let height = CGFloat(data.height ?? 0)
            let ratio = height / width
            /// pading bottom cell là 8
            /// height của stackview chứa 2 label là 40
            return tableView.frame.width * ratio + 40 + 6
        }
        return 300
    }
}

@available(iOS 13.0, *)
extension HomeViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let maxLength = 15
        let currentText = textField.text ?? ""
        
        if string.isEmpty {
            return true
        }
        
        guard let stringRange = Range(range, in: currentText) else {
            return false
        }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        if updatedText.count > maxLength {
            return false
        }
        
        let pattern = "^[a-zA-Z0-9!@#$%^&*():.,<>/\\[\\]?]+$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: updatedText.utf16.count)
        
        if regex?.firstMatch(in: updatedText, range: range) == nil {
            let newString = updatedText.folding(options: .diacriticInsensitive, locale: .current)
            textField.text = newString
        }
        return regex?.firstMatch(in: updatedText, range: range) != nil
    }
}
