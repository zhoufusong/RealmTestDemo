//
//  RealmModel.swift
//  RealmTestDemo
//
//  Created by apple on 2017/7/6.
//  Copyright © 2017年 XinGuang. All rights reserved.
//

import Foundation
import RealmSwift

class Person:Object{
    let dogs = List<Dog>()  //对多关系
}

class Dog:Object{
    dynamic var name = ""
    dynamic var age = 0
    dynamic var price = 0.0
    dynamic var color = ""
    let owners = LinkingObjects.init(fromType: Person.self, property: "dogs")   //反向关系
}
