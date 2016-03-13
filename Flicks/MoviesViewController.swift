//
//  MoviesViewController.swift
//  Flicks
//
//  Created by TriNgo on 3/9/16.
//  Copyright © 2016 TriNgo. All rights reserved.
//

import UIKit
import AFNetworking
import MBProgressHUD

class MoviesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var networkErrorLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var switchTableAndCollection: UISegmentedControl!
    
    var searchActive : Bool = false
    var movies = [NSDictionary]?()
    var moviesFiltered = [NSDictionary]?()
    var endpoint : String!
    var isFirstLoading : Bool = true
    var refreshControl : UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Initialize a UIRefreshControl
        self.refreshControl = UIRefreshControl()
        self.refreshControl.addTarget(self, action: "loadDataFromNetwork:", forControlEvents: UIControlEvents.ValueChanged)
        tableView.insertSubview(refreshControl, atIndex: 0)
        
        tableView.dataSource = self
        tableView.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        searchBar.delegate = self
        
        // Hide collection view by default
        collectionView.hidden = true
        
        // Request API
        loadDataFromNetwork(refreshControl)
    }
    
    @IBAction func onSwitchChanged(sender: AnyObject) {
        switch switchTableAndCollection.selectedSegmentIndex {
        case 0: // table view is shown
            collectionView.hidden = true
            tableView.hidden = false
            tableView.insertSubview(self.refreshControl, atIndex: 0)
            break
        case 1: // collection view is shown
            collectionView.hidden = false
            tableView.hidden = true
            collectionView.insertSubview(self.refreshControl, atIndex: 0)
            break
        default:
            collectionView.hidden = true
            tableView.hidden = false
//            tableView.insertSubview(refreshControl, atIndex: 0)
            break
        }
    }
    func loadDataFromNetwork(refreshControl : UIRefreshControl){
        if Reachability.isConnectedToNetwork() {
            networkErrorLabel.hidden = true
        }else{
            networkErrorLabel.hidden = false
        }
        
        // Do any additional setup after loading the view.
        let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = NSURL(string: "https://api.themoviedb.org/3/movie/\(endpoint)?api_key=\(apiKey)")
        let request = NSURLRequest(
            URL: url!,
            cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData,
            timeoutInterval: 10)
        
        let session = NSURLSession(
            configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
            delegate: nil,
            delegateQueue: NSOperationQueue.mainQueue()
        )
        
        if isFirstLoading {
            // Display HUD right before the request is made
            MBProgressHUD.showHUDAddedTo(self.view, animated: true)
            isFirstLoading = false
        }
        
        let task: NSURLSessionDataTask = session.dataTaskWithRequest(request,
            completionHandler: { (dataOrNil, response, error) in
                
                // Hide HUD once the network request comes back (must be done on main UI thread)
                MBProgressHUD.hideHUDForView(self.view, animated: true)
                
                if let data = dataOrNil {
                    if let responseDictionary = try! NSJSONSerialization.JSONObjectWithData(
                        data, options:[]) as? NSDictionary {
                            
                            self.movies = responseDictionary["results"] as? [NSDictionary]
                            self.tableView.reloadData()
                            self.collectionView.reloadData()
                            
                            // Tell the refreshControl to stop spinning
                            refreshControl.endRefreshing()
                    }
                }else{
                    refreshControl.endRefreshing()
                }
        })
        task.resume()
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
//        searchActive = false;
        self.searchBar.endEditing(true)
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        moviesFiltered = movies?.filter({(data) -> Bool in
            let tmp : NSString = data["title"] as! String
            let range = tmp.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch)
            return range.location != NSNotFound
        })
        
        if (moviesFiltered!.count == 0){
            searchActive = false
        }else{
            searchActive = true
        }
        
        self.tableView.reloadData()
        self.collectionView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
    
        // Set the number of items in your table view.
        return numberOfItemsInSection()
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{

        let cell = tableView.dequeueReusableCellWithIdentifier("MovieCell", forIndexPath: indexPath) as! MovieCell
        cell.selectionStyle = .None
        
        let movie : NSDictionary
        if searchActive {
            movie = moviesFiltered![indexPath.row]
        }else{
            movie = movies![indexPath.row]
        }

        let title = movie["title"] as! String
        let overview = movie["overview"] as! String
        
        cell.titleLabel.text = title
        cell.overviewLabel.text = overview
        
        let baseUrl = "http://image.tmdb.org/t/p/w500/"
        if let posterPath = movie["poster_path"] as? String {
            let imageUrl = NSURL(string: baseUrl + posterPath)
            cell.posterView.setImageWithURL(imageUrl!)
        }
        
        return cell
    }
    
    /**
     * Collection view method
     */
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        // Set the number of items in your collection view.
        return numberOfItemsInSection()
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("MovieCollectionCell", forIndexPath: indexPath) as! MovieCollectionCell

        let movie : NSDictionary
        if searchActive {
            movie = moviesFiltered![indexPath.row]
        }else{
            movie = movies![indexPath.row]
        }
        
        let title = movie["title"] as! String
//        let overview = movie["overview"] as! String
        
        cell.titleLabel.text = title
//        cell.overviewLabel.text = overview
        
        let baseUrl = "http://image.tmdb.org/t/p/w500/"
        if let posterPath = movie["poster_path"] as? String {
            let imageUrl = NSURL(string: baseUrl + posterPath)
            cell.posterView.setImageWithURL(imageUrl!)
        }
        
        return cell
    }
    
    /**
     * Common function
     */
    func numberOfItemsInSection() -> Int{
        if searchActive {
            return moviesFiltered!.count
        }
        
        if let movies = movies{
            return movies.count
        }else{
            return 0
        }
    }
    
    /*
    // MARK: - Navigation
    */
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        var movie = NSDictionary()
        
        if tableView.hidden { // collection view is shown
            let cell = sender as! UICollectionViewCell
            let indexPath = collectionView.indexPathForCell(cell)
            if searchActive {
                movie = moviesFiltered![indexPath!.row]
            }else{
                movie = movies![indexPath!.row]
            }
        }else{ // table view is shown
            let cell = sender as! UITableViewCell
            let indexPath = tableView.indexPathForCell(cell)
            if searchActive {
                movie = moviesFiltered![indexPath!.row]
            }else{
                movie = movies![indexPath!.row]
            }
        }
        
        let detailViewController = segue.destinationViewController as! DetailViewController
        detailViewController.movie = movie
        
    }

}
