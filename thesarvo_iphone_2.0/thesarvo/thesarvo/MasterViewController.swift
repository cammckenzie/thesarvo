//
//  MasterViewController.swift
//  thesarvo
//
//  Created by Jon Nermut on 30/12/2014.
//  Copyright (c) 2014 thesarvo. All rights reserved.
//

import UIKit
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class SegueCallback
{
    let function : (UIViewController) -> ()
    init (_ function: @escaping (UIViewController) -> () )
    {
        self.function = function
    }
}

class TOCCell: UITableViewCell
{
    var node: GuideNode?
}

class SearchCell: UITableViewCell
{
    var indexEntry: IndexEntry?
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        super.init(style: UITableViewCellStyle.subtitle, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
}

class MasterViewController: UITableViewController, UISearchResultsUpdating
{
    var guide: Guide?
    var showingTOC: Bool { return self.guide != nil }
    
    var detailViewController: DetailViewController? = nil
    
    var data : View?
    
    var searchController: UISearchController!
    
    var searchString: String?
    
    var mainDataSource: TableViewDataSource?
    
    @IBOutlet weak var updateView: UIView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var updateLabel: UILabel!
    
    
    var searching = false
    var searchAgain = false
    
    var updateTimer: Timer? = nil
    
    static var last: MasterViewController? = nil

    override func awakeFromNib()
    {
        super.awakeFromNib()
        if UIDevice.current.userInterfaceIdiom == .pad
        {
            self.clearsSelectionOnViewWillAppear = false
            self.preferredContentSize = CGSize(width: 320.0, height: 600.0)
        }
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        /*
        self.navigationItem.leftBarButtonItem = self.editButtonItem()

        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewObject:")
        self.navigationItem.rightBarButtonItem = addButton
        */
        
        if (data == nil)
        {
            data = Model.instance.rootView
            //navigateToDetail("guide.9404494", title: "Introduction", elementId: nil, showDetail: false)
        }

        /* FIXME
        if let split = self.splitViewController
        {
            let controllers = split.viewControllers
            self.detailViewController = controllers[controllers.count-1].topViewController as? DetailViewController
        }
        */
        
        //self.tableView.registerClass(SearchCell.self, forCellReuseIdentifier: "SearchCell")
        //self.tableView.registerClass(TOCCell.self, forCellReuseIdentifier: "TOCCell")
        
        searchController = UISearchController(searchResultsController: nil)
        self.searchController.searchResultsUpdater = self;
        self.searchController.dimsBackgroundDuringPresentation = false;
        //self.searchController.searchBar.scopeButtonTitles = @[NSLocalizedString(@"ScopeButtonCountry",@"Country"),NSLocalizedString(@"ScopeButtonCapital",@"Capital")];
        //self.searchController.searchBar.delegate = self;
        self.searchController.searchBar.scopeButtonTitles = []
        self.tableView.tableHeaderView = self.searchController.searchBar;
        self.tableView.tableHeaderView?.isOpaque = true
        self.searchController.searchBar.isOpaque = true
        self.definesPresentationContext = true;
        self.searchController.searchBar.sizeToFit()
        self.searchController.searchBar.placeholder = "Search for crag, climb, grade, ***"
        if showingTOC
        {
            self.searchController.searchBar.placeholder = "Search within page"
        }
        self.searchController.searchBar.backgroundColor = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1)
    
    
        self.tableView.allowsMultipleSelection = false
    }
    
    dynamic func updateUpdateView()
    {
        self.updateView.isHidden = false
        let gd = Model.instance.guideDownloader
        
        self.updateLabel.text = gd.labelText
        
        if (gd.syncing)
        {
            self.progressView.isHidden = false
            self.progressView.progress = gd.progress
        }
        else
        {
            self.progressView.isHidden = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        MasterViewController.last = self

        
//        if (data != nil && data?.text != nil)
//        {
//             self.navigationItem.title = data?.text
//        }
        
        if (data == nil)
        {
            data = Model.instance.rootView
            
            
        }

        
        if (mainDataSource == nil)
        {
            setupDatasource()
        }
        
        
        if data?.viewId == "home" && !showingTOC
        {
            updateUpdateView()
            updateTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(MasterViewController.updateUpdateView), userInfo: nil, repeats: true)
            
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        if let ut = updateTimer
        {
            ut.invalidate()
        }
        self.updateTimer = nil
    }
    

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupTOCDatasource()
    {
        runInBackground()
        {
            
            if let guide = self.guide
            {
                let filter = self.searchString
                
                // sectioned by header then climb
                let d = guide.getHeadingsAndClimbs()
                d.reuseIdentifier = "TOCCell"
                
                if let filter = filter
                {
                    if filter.characters.count > 0
                    {
                        d.rows = d.rows.filter()
                        {
                            (guideNode: GuideNode) in
                            (guideNode.searchString ?? "").containsCaseInsensitive(filter)
                        }
                    }
                }
                
                d.cellConfigurator =
                {
                    (cell: UITableViewCell!, node: GuideNode) in
                    if let cell = cell as? TOCCell
                    {
                        cell.node = node
                        cell.textLabel?.text = node.description
                        cell.textLabel?.adjustsFontSizeToFitWidth = true
                        
                        cell.backgroundColor = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1)
                        
                        cell.selectedBackgroundView = UIView()
                        cell.selectedBackgroundView?.backgroundColor = UIColor(red: 0, green: 0, blue: 0.5, alpha: 0.8)
                        
                        if let tn = node as? TextNode
                        {
                            if tn.clazz == "heading1"
                            {
                                cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 15)
                                cell.indentationLevel = 0
                            }
                            else if tn.clazz == "heading2"
                            {
                                cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 14)
                                cell.indentationLevel = 0
                            }
                            else
                            {
                                cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 13)
                                cell.indentationLevel = 1
                                
                            }
                            

                        }
                        else if let h = node as? HeaderNode
                        {
                            cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 14)
                            cell.indentationLevel = 0
                        }
                        else
                        {
                            cell.textLabel?.font = UIFont.systemFont(ofSize: 12)
                            cell.indentationLevel = 3
                            cell.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
                            
                        }
                        
                    }
                } as! (UITableViewCell?, GuideNode) -> (Void)
                /*
                if (shouldFilter)
                {
                for sect in d.sections
                {
                sect.rows = sect.rows.filter()
                {
                (guideNode: GuideNode) in
                (guideNode.searchString ?? "").containsCaseInsensitive(filter)
                }
                }
                }
                */
                self.tableView.rowHeight = 32
                self.mainDataSource = d.tableViewDataSource
                
                runOnMain()
                {
                    self.tableView.dataSource = self.mainDataSource
                    self.tableView.reloadData()
                }
            }
        }

    }

    func setupDatasource()
    {
        if guide != nil
        {
            setupTOCDatasource()
            return
        }
        
        let rows = (data?.listItems).valueOr([])
        let d = SingleSectionDataSource(rows: rows)
        {
            cell, li in

            cell?.textLabel?.text = li.text
            cell?.accessoryType = li.viewId != nil ? UITableViewCellAccessoryType.disclosureIndicator : UITableViewCellAccessoryType.none;
            cell?.textLabel?.adjustsFontSizeToFitWidth = true
            var level = 0
            if let l = li.level
            {
                level = l-1
            }
            
            cell?.textLabel?.font = UIFont.systemFont( ofSize: CGFloat(18-level*2) );
            cell?.indentationLevel = level;
            cell?.indentationWidth = 25;
            cell?.backgroundColor = UIColor.clear
            cell?.selectedBackgroundView = UIView()
            cell?.selectedBackgroundView?.backgroundColor = UIColor(red: 0, green: 0, blue: 0.5, alpha: 0.8)
        }
        self.mainDataSource = d.tableViewDataSource
        self.tableView.dataSource = mainDataSource
        self.tableView.reloadData()
    }


    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        let dest: UIViewController = segue.destination as UIViewController
        
        if (sender is SegueCallback)
        {
            (sender as! SegueCallback).function(dest)
        }
        
        /*
        if segue.identifier == "showDetail"
        {
            if let indexPath = self.tableView.indexPathForSelectedRow()
            {
                let li = data?.listItems[indexPath.row]
                let controller = (segue.destinationViewController as UINavigationController).topViewController as DetailViewController
                
                if (li != nil)
                {
                    controller.viewId = li!.viewId
                }
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
*/
    }

    
    func segueToDrilldown(_ viewId: String)
    {
        let callback = SegueCallback
        {
            (vc: UIViewController) in
            let mtvc = vc as! MasterViewController
            let v = Model.instance.views[viewId]
            mtvc.data = v
            mtvc.navigationItem.title = viewId
        }
        
        self.performSegue(withIdentifier: "showMaster", sender: callback)
    }
    
    func navigateToDetail(_ viewId: String, title: String?, elementId: String? = nil, showDetail: Bool = true)
    {
        var vid = viewId.removePrefixIfPresent("guide.")
        var guide: Guide?
        if (!vid.hasPrefix("http.") && vid.characters.count > 0)
        {
            guide = Guide(guideId: vid)
        }
        
        let fcvc = self.storyboard?.instantiateViewController(withIdentifier: "detailViewController") as! DetailViewController
        fcvc.guide = guide
        fcvc.viewId = viewId
        fcvc.navigationItem.title = title
        if let el = elementId
        {
            fcvc.elemendId = el
        }
        AppDelegate.instance().setDetail(fcvc, showNow: showDetail)
        
        //var delay = 0.0
        if let g = guide
        {
            //delay = 0.2
            let ddcallback = SegueCallback
            {
                (vc: UIViewController) in
                let mtvc = vc as! MasterViewController
                mtvc.guide = g
                let t = title ?? ""
                mtvc.navigationItem.title = "\(t)"
            }
            
            runInBackground()
            {
                if (g.getHeadingsAndClimbs().rows.count > 0)
                {
                    runOnMain()
                    {
                        self.performSegue(withIdentifier: "showMaster", sender: ddcallback)
                    }
                }
            }
        }
        
        /*
        let callback = SegueCallback
        {
            (vc: UIViewController) in
            if let fcvc = DetailViewController.getFromVC(vc)
            {
                fcvc.guide = guide
                fcvc.viewId = viewId
                fcvc.navigationItem.title = title
                if let el = elementId
                {
                    fcvc.elemendId = el
                }
            }
        }
        
        // drill down in the master to a TOC
        var delay = 0.0
        if let g = guide
        {
            delay = 0.2
            let ddcallback = SegueCallback
            {
                (vc: UIViewController) in
                let mtvc = vc as! MasterViewController
                mtvc.guide = g
                    
            }
            self.performSegueWithIdentifier("showMaster", sender: ddcallback)
        }

        
        runAfterDelay(delay)
        {
        
            AppDelegate.instance().hideMasterIfNecessary()
            self.performSegueWithIdentifier("showDetail", sender: callback)
        }
*/
    }
    

    
    
    func childSelected(_ selected: ListItem)
    {
        if let viewId = selected.viewId
        {
            if (viewId == "Map")
            {
                /*
                let callback = SegueCallback
                {
                    (vc: UIViewController) in
                }
                self.performSegueWithIdentifier("showMap", sender: callback)
*/
                if !Model.instance.indexingDone
                {
                    return
                }
                
                let mc = self.storyboard?.instantiateViewController(withIdentifier: "mapController") as! MapViewController
                AppDelegate.instance().setDetail(mc)

            }
            else if (viewId == "Settings")
            {
                let sc = self.storyboard?.instantiateViewController(withIdentifier: "settingsController") as! SettingsViewController
                AppDelegate.instance().setDetail(sc)
            }
            else if (viewId.hasPrefix("guide.") || viewId.hasPrefix("http"))
            {
                navigateToDetail(viewId, title: selected.text)

            }
            else
            {
                segueToDrilldown(viewId)
            }
        }
        
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath)
    {
        
        // I don't know why exactly, but this hammer seems essential 
        // to clearing the previous selection, which is doing a lot of extra work, but buggered if I can get it to clear otherwise
        tableView.reloadData()
        
    }
    
    func navigateToEntry(_ entry: IndexEntry)
    {
        let elementId = entry.node?.elementId
        navigateToDetail(entry.guide.guideId, title: entry.guide.name, elementId: elementId)

    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        
        let cell = tableView.dataSource?.tableView(tableView, cellForRowAt: indexPath)
        
        if let searchCell = cell as? SearchCell
        {
            if let entry = searchCell.indexEntry
            {
                self.navigateToEntry(entry)
            }
        }
        else if let tocCell = cell as? TOCCell
        {
            if let node = tocCell.node
            {
                if let dvc = DetailViewController.last
                {
                    dvc.scrollToId(node.elementId)
                    AppDelegate.instance().hideMasterIfNecessary()
                }
            }
        }
        else
        {
            if (data?.listItems.count > (indexPath as NSIndexPath).row)
            {
                if let c = data?.listItems[(indexPath as NSIndexPath).row]
                {
                    childSelected(c)
                }
            }
        }
    }

    internal func updateSearchResults(for searchController: UISearchController)
    {
        searchString = searchController.searchBar.text
        updateSearchResults()
    }

    func updateSearchResults()
    {
        if self.showingTOC
        {
            setupTOCDatasource()
            return
        }
        
        let model = Model.instance
        
        if (!model.indexingDone)
        {
            return
        }
        
        if (searching)
        {
            searchAgain = true
            return
        }
        
        if (searchString == nil || searchString!.characters.count < 2)
        {
            self.tableView.dataSource = mainDataSource
            self.tableView.reloadData()
            return
        }
        
        if let searchString = searchString
        {

            
            searching = true
            runInBackground()
            {
                let results = model.search(searchString)
                
                let searchDataSource = SingleSectionDataSource(rows: results)
                {
                    (cell: UITableViewCell?, entry: IndexEntry) in
                    if let c = cell as? SearchCell
                    {
                        c.indexEntry = entry
                    }
                    
                    guard let cell = cell else { return }
                    
                    cell.textLabel?.text = entry.searchString.ltrimmed()
                    
                    cell.accessoryType = .none
                    cell.textLabel?.adjustsFontSizeToFitWidth = true
                    cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 14)
                    
                    cell.indentationLevel = 0
                    
                    cell.backgroundColor = nil
                    
                    if entry.node != nil
                    {
                        cell.detailTextLabel?.text = entry.guide.name ?? ""
                    }
                    else
                    {
                        cell.detailTextLabel?.text = ""
                    }
                    
                }
                searchDataSource.reuseIdentifier = "SearchCell"
                
                runOnMain()
                {
                    self.tableView.dataSource = searchDataSource.tableViewDataSource
                    self.tableView.reloadData()
                    
                    self.searching = false
                    if (self.searchAgain)
                    {
                        self.searchAgain = false
                        self.updateSearchResults()
                    }
                }
            }
        }
    }

}


