Realm是一个跨平台的移动数据库解决方案，旨在成为 SQLite 和 Core Data 的更易用的替代方案。

主要的优势有：

- 简单易用，大部分操作几行代码即可搞定
- 不是基于SQLite和CoreData，而是有自己的数据库存储引擎，且基于C++编写保证了效率
- 跨平台，安卓、iOS和RN均可以用
- 可视化，提供了Realm Browser可视化工具查看和操作数据库

可以采用cocoapods安装，非常方便，有官方文档，便于使用

其实没有比看官方文档和github上的开源代码更好的学习方式了，也由于篇幅有限而内容较多就选择一些重要常用的内容写一下。

1、数据模型

- 模型定义及对多、对一、反向等关系

Realm的数据模型是基于标准swift类来进行定义的（结构体是不行的，因为Realm 是依赖于动态对象而设计的），使用属性来完成模型定义，区别就是继承Object或者一个已存在的Realm模型类。限制是某个对象只能在其被创建的那个线程中使用。数据关系可以通过定义属性类型或list来指定对一或者对多关系。如下所示

```
import Foundation
import RealmSwift
 
//消费类型
class ConsumeType:Object {   //需要继承Object才能在realm中使用
    //类型名
    dynamic var name = ""
}
 
//消费条目
class ConsumeItem:Object {
    //条目名
    dynamic var name = ""
    //金额
    dynamic var cost = 0.00
    //时间
    dynamic var date = Date()
    //所属消费类别
    dynamic var type:ConsumeType?  //指定了ConsumeType和ConsumeItem的关系，通过属性完成对一关系的绑定
}

class Person: Object {
    // 其余的属性声明...
    let dogs = List<Dog>() //对多关系，使用list，与Array类似使用下标访问，只不过只能存放Object子类类型
}

class Dog: Object {
    dynamic var name = ""
    dynamic var age = 0
    let owners = LinkingObjects(fromType: Person.self, property: "dogs") //借助链接对象属性，来表示这些反向关系，避免手动同步双向关系容易出错
}
```

String、NSDate以及 NSData 属性能够通过标准的 Swift 语法声明为可空类型或者非空类型。

Realm 模型的属性需要设置为dynamic var特性，以便其能够被数据库底层数据所访问。有两个例外： List和RealmOptional不能被设为动态属性，因为泛型属性不能在 Objective‑C 运行时中被识别，而 dynamic属性会被用于进行动态调度。因此这两个类型应当始终声明为 let。

- 设置主键

重写 Object.primaryKey()可以设置模型的主键。声明主键之后，对象将被允许查询，更新速度更加高效，并且要求每个对象保持唯一性。一旦带有主键的对象被添加到 Realm 之后，该对象的主键将不可修改。

```
class Person: Object {
  dynamic var id = 0
  dynamic var name = ""

  override static func primaryKey() -> String? {
    return "id"
  }
}
```

- 添加索引属性

重写 Object.indexedProperties() 方法可以为数据模型中需要添加索引的属性建立索引，Realm 支持字符串、整数、布尔值以及 NSDate属性作为索引。对属性进行索引可以减少插入操作的性能耗费，加快比较检索的速度。

```
class Book: Object {
  dynamic var price = 0
  dynamic var title = ""

  override static func indexedProperties() -> [String] {
    return ["title"]
  }
}
```

- 设置忽略属性

重写Object.ignoredProperties()可以防止 Realm 存储数据模型的某个属性。

```
class Person: Object {
  dynamic var tmpID = 0  //忽略属性
  var name: String { // 只读属性将被自动忽略
    return "\(firstName) \(lastName)"
  }
  dynamic var firstName = ""
  dynamic var lastName = ""
 
  override static func ignoredProperties() -> [String] {
    return ["tmpID"]
  }
}
```

2、对象存储：

- 创建对象（定义号Object子类后，3种方式实例化：初始化后属性赋值；字典；数组），嵌套属性同理

```
// (1) 创建一个狗狗对象，然后设置其属性
var myDog = Dog()
myDog.name = "大黄"
myDog.age = 10

// (2) 通过字典创建狗狗对象
let myOtherDog = Dog(value: ["name" : "豆豆", "age": 3])

// (3) 通过数组创建狗狗对象
let myThirdDog = Dog(value: ["豆豆", 5])
```

- 添加数据

```
// 创建一个 Person 对象
let author = Person()
author.name = "金刚"

// 获取默认的 Realm 实例
let realm = try! Realm()
// 每个线程只需要使用一次即可

// 通过事务将数据添加到 Realm 中
try! realm.write {
  realm.add(author)
}
```

- 更新数据

```
//1、内容属性直接更新
// 在一个事务中更新对象
try! realm.write {
  author.name = "托马斯·品钦"
}
//2、通过主键更新
// 创建一个带有主键的“书籍”对象，作为事先存储的书籍
let cheeseBook = Book()
cheeseBook.title = "奶酪食谱"
cheeseBook.price = 9000
cheeseBook.id = 1

// 通过 id = 1 更新该书籍
try! realm.write {
  realm.add(cheeseBook, update: true)
}
//3、键值编码  Object、Result 以及 List都遵守键值编码KVC机制
let persons = realm.objects(Person)
try! realm.write {
  persons.first?.setValue(true, forKeyPath: "isFirst")
  // 将每个人的 planet 属性设置为“地球”
  persons.setValue("地球", forKeyPath: "planet")
}
```

- 删除数据

```
// 在事务中删除一个对象
try! realm.write {
  realm.delete(cheeseBook)
}
// 从 Realm 中删除所有数据
try! realm.write {
  realm.deleteAll()
}
```

3、查询

所有的查询（包括查询和属性访问）在 Realm 中都是延迟加载的，只有当属性被访问时，才能够读取相应的数据。通过查询操作，Realm 将会返回包含 Object集合的Results实例

```
//基本方法
let dogs = realm.objects(Dog) // 从默认的 Realm 数据库中，检索所有狗狗

//条件查询，支持链式查询
// 使用断言字符串查询
var tanDogs = realm.objects(Dog).filter("color = '棕黄色' AND name BEGINSWITH '大'")
// 使用 NSPredicate 查询
let predicate = NSPredicate(format: "color = %@ AND name BEGINSWITH %@", "棕黄色", "大")
tanDogs = realm.objects(Dog).filter(predicate)

//排序
// 排序名字以“B”开头的棕黄色狗狗
let sortedDogs = realm.objects(Dog.self).filter("color = 'tan' AND name BEGINSWITH 'B'").sorted(byKeyPath: "name")
```

4、数据库路径

- 默认数据库

通过Realm()初始化来访问，路径位于Documents下的default.realm文件

- 数据库路径配置

通过Realm.Configuration您可以配置诸如 Realm 文件在何处存储之类的信息；使用Realm.Configuration.defaultConfiguration = config来为默认的 Realm 数据库进行配置，例如：

```
func setDefaultRealmForUser(username: String) {
  var config = Realm.Configuration()

  // 使用默认的目录，但是使用用户名来替换默认的文件名
  config.fileURL = config.fileURL!.deletingLastPathComponent()
                         .appendingPathComponent("\(username).realm")

  // 将这个配置应用到默认的 Realm 数据库当中
  Realm.Configuration.defaultConfiguration = config
}
```

- 内存数据库

通常情况下，Realm 数据库是存储在硬盘中的，但是您能够通过设置inMemoryIdentifier以创建一个完全在内存中运行的数据库。

```
let realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "MyInMemoryRealm"))
```

- 错误处理

使用 Swift 内置的错误处理机制,创建数据库可能会失败，但只会发生在同一个线程首次初始化，后续都会用缓存

```
do {
  let realm = try Realm()
} catch let error as NSError {
  // 错误处理
}
```

5、加密

加密后的 Realm文件不能跨平台使用（因为 NSFileProtection 只有 iOS 才可以使用）；加密过的 Realm 只会带来很少的额外资源占用（通常最多只会比平常慢10%）。

```
// 产生随机密钥
var key = Data(count: 64)
_ = key.withUnsafeMutableBytes { bytes in
  SecRandomCopyBytes(kSecRandomDefault, 64, bytes)
}

// 打开加密文件
let config = Realm.Configuration(encryptionKey: key)
do {
  let realm = try Realm(configuration: config)
  // 和往常一样使用 Realm 即可
  let dogs = realm.objects(Dog).filter("name contains 'Fido'")
} catch let error as NSError {
  // 如果密钥错误，`error` 会提示数据库不可访问
  fatalError("Error opening realm: \(error)")
}
```

6、线程相关

在单线程中，随便怎么玩都可以，只要注意把修改操作写到事务中。

多线程中，需要注意的是不能让多个线程都持有同一个 Realm 对象的 *实例* 。如果多个线程需要访问同一个对象，那么它们分别会获取自己所需要的实例（否则在一个线程上发生的更改就会造成其他线程得到不完整或者不一致的数据）。

Realm、Object、Results或者List受到线程的限制，这意味着它们只能够在被创建的线程上使用，否则就会抛出异常。

在不同的线程中使用同一个 Realm 文件，需要为应用的每一个线程初始化一个新的Realm 实例。也就是说Realm 对象并不是线程安全的，并且它也不能够跨线程共享，因此您必须要为每一个您想要执行读取或者写入操作的线程或者 dispatch 队列创建一个 Realm 实例。









