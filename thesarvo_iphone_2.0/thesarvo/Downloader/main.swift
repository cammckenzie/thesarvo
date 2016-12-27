//
//  main.swift
//  Downloader
//
//  Created by Jon Nermut on 26/12/2015.
//  Copyright © 2015 thesarvo. All rights reserved.
//

import Foundation

print("Hello, World!")

let gd = GuideDownloader(directory: "/git/thesarvo/thesarvo_iphone_2.0/thesarvo/www/data")
gd.desktopMode = true
gd.startSync()

Thread.sleep(forTimeInterval: 5.0)
while(gd.syncing)
{
    Thread.sleep(forTimeInterval: 1.0)
    print(gd.labelText)
}
