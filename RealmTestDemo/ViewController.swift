//
//  ViewController.swift
//  RealmTestDemo
//
//  Created by apple on 2017/7/6.
//  Copyright © 2017年 XinGuang. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    static var count = 0;

    @IBAction func insertData(_ sender: UIButton) {
        
        ViewController.count = ViewController.count+1;

        let myDog = Dog(value: ["name" : "Peas", "age": ViewController.count,"price":1300,"color":"orange"])
        let myPerson = Person(value:["dogs":[myDog]])
        
        
        try! sharedRealm.write {
            sharedRealm.add(myDog)
            sharedRealm.add(myPerson)
            print("add data")
        }
        
    }
    @IBAction func updateData(_ sender: UIButton) {

        let dogs = sharedRealm.objects(Dog.self)
        
        try! sharedRealm.write {
            dogs.setValue("xiaoming", forKey: "name")
            print("update data")
        }
    }
    @IBAction func deleteData(_ sender: UIButton) {
        try! sharedRealm.write {
            sharedRealm.deleteAll()
            print("delete all data")
        }
        
    }
    @IBAction func queryData(_ sender: UIButton) {
        
        let dogs = sharedRealm.objects(Dog.self)
        if !dogs.isEmpty{
            for i in 0..<dogs.count{
                print("the dog name is \(dogs[i].name), age is \(dogs[i].age), price is \(dogs[i].price), color is \(dogs[i].color)")
            }
        }else{
            print("the query result is empty!")
        }
    }
    @IBAction func conditionQuery(_ sender: UIButton) {
        let dogs = sharedRealm.objects(Dog.self).filter("name = 'xiaoming'").filter("color = 'orange'")
        if !dogs.isEmpty{
            for i in 0..<dogs.count{
                print("the dog name is \(dogs[i].name), age is \(dogs[i].age), price is \(dogs[i].price), color is \(dogs[i].color)")
            }
        }else{
            print("the condition filter result is empty!")
        }

    }
    @IBAction func sortedQuery(_ sender: UIButton) {
        let dogs = sharedRealm.objects(Dog.self).filter("name = 'xiaoming'").sorted(byKeyPath: "age", ascending: false).filter("color = 'orange'")
        if !dogs.isEmpty{
            for i in 0..<dogs.count{
                print("the dog name is \(dogs[i].name), age is \(dogs[i].age), price is \(dogs[i].price), color is \(dogs[i].color)")
            }
        }else{
            print("the sorted filter result is empty!")
        }

    }
    override func viewDidLoad() {
        super.viewDidLoad()
        print("\(NSHomeDirectory())")
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

