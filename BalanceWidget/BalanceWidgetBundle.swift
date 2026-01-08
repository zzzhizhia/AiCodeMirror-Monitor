//
//  BalanceWidgetBundle.swift
//  BalanceWidget
//
//  Created by zzzhizhi on 1/6/26.
//

import WidgetKit
import SwiftUI

@main
struct BalanceWidgetBundle: WidgetBundle {
    var body: some Widget {
        SmallBalanceWidget()
        BalanceWidget()
    }
}
