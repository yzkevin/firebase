//
//  File.swift
//  File
//
//  Created by Morten Bek Ditlevsen on 21/09/2021.
//

import Collections
import Foundation

@objc public class FEmptyNode: NSObject {
    @objc public static var empty: FNode = FChildrenNode(children: [:])
    @objc public static var emptyNode: FNode = FChildrenNode(children: [:])
}

private let kMinName = "[MIN_NAME]"
private let kMaxName = "[MAX_NAME]"

@objc public class FNamedNode: NSObject, NSCopying {
    @objc public var name: String
    @objc public var node: FNode
    @objc public init(name: String, andNode node: FNode) {
        self.name = name
        self.node = node
    }
    @objc public class func nodeWithName(_ name: String, node: FNode) -> FNamedNode {
        FNamedNode(name: name, andNode: node)
    }
    @objc public static var min: FNamedNode = FNamedNode(name: kMinName, andNode: FEmptyNode.empty)
    @objc public static var max: FNamedNode = FNamedNode(name: kMaxName, andNode: FEmptyNode.empty)

    @objc public override func copy() -> Any {
        self
    }

    @objc public func copy(with zone: NSZone? = nil) -> Any {
        self
    }

    @objc public override var description: String {
        "NamedNode[\(name)] \(node)"
    }

    @objc public override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? FNamedNode else { return false }
        if self === object { return true }
        guard name == object.name else { return false }
        return node.isEqual(object.node)
    }

    @objc public override var hash: Int {
        31 * name.hash + node.hash
    }
}

@objc public class FChildrenNode: NSObject, FNode {

    @objc public func isLeafNode() -> Bool {
        false
    }
    
    @objc public func getPriority() -> FNode {
        priorityNode ?? FEmptyNode.empty
    }

    @objc public func updatePriority(_ priority: FNode) -> FNode {
        if children.isEmpty {
            return FEmptyNode.empty
        } else {
            return FChildrenNode(priority: priority, children: self.children)
        }
    }

    @objc public func getImmediateChild(_ childKey: String) -> FNode {
        if childKey == ".priority" {
            return getPriority()
        } else {
            return children[childKey] ?? FEmptyNode.empty
        }
    }

    @objc public func getChild(_ path: FPath) -> FNode {
        guard let front = path.getFront() else {
            return self
        }
        return getImmediateChild(front).getChild(path.popFront())
    }

    @objc public func predecessorChildKey(_ childKey: String) -> String? {
        guard let keyIndex = children.keys.firstIndex(of: childKey), keyIndex > 0 else {
            return nil
        }
        return children.keys.elements[keyIndex - 1]
    }

    @objc public func updateImmediateChild(_ childKey: String, withNewChild newChildNode: FNode) -> FNode {
        guard childKey != ".priority" else {
            return updatePriority(newChildNode)
        }

        var newChildren = self.children
        if newChildNode.isEmpty {
            newChildren.removeValue(forKey: childKey)
        } else {
            newChildren[childKey] = newChildNode
        }
        // XXX SORT USING KEY SORT
        newChildren.sort { a, b in
            FUtilitiesSwift.compareKey(a.key, b.key) == .orderedAscending
        }

        if newChildren.isEmpty {
            return FEmptyNode.empty
        } else {
            return FChildrenNode(priority: getPriority(), children: newChildren)
        }
    }

    @objc public func updateChild(_ path: FPath, withNewChild newChildNode: FNode) -> FNode {
        guard let front = path.getFront() else {
            return newChildNode
        }

        assert(front != ".priority", ".priority must be the last token in a path.")
        let newImmediateChild = getImmediateChild(front).updateChild(path.popFront(), withNewChild: newChildNode)
        return updateImmediateChild(front, withNewChild: newImmediateChild)
    }

    @objc public func hasChild(_ childKey: String) -> Bool {
        !getImmediateChild(childKey).isEmpty
    }

    @objc public var isEmpty: Bool {
        children.isEmpty
    }

    @objc public func numChildren() -> Int {
        children.count
    }

    @objc public func val() -> Any {
        val(forExport: false)
    }

    @objc public func val(forExport exp: Bool) -> Any {
        guard !isEmpty else {
            return NSNull()
        }
        var numKeys = 0
        var maxKey = 0
        var allIntegerKeys = true
        let obj = NSMutableDictionary(capacity: children.count)
        for (key, childNode) in children {
            obj.setObject(childNode.val(forExport: exp), forKey: key as NSString)
            numKeys += 1

            // If we already found a string key, don't bother with any of this
            if !allIntegerKeys { continue }

            // Treat leading zeroes that are not exactly "0" as strings
            if key.first == "0" && key.count > 1 {
                allIntegerKeys = false
                continue
            }
            if let keyAsInt = FUtilitiesSwift.intForString(key) {
                maxKey = max(maxKey, keyAsInt)
            } else {
                allIntegerKeys = false
            }
        }
        if !exp && allIntegerKeys && maxKey < 2 * numKeys {
            // convert to an array
            let array = NSMutableArray(capacity: maxKey + 1)
            for i in 0...maxKey {
                if let child = obj["\(i)"] {
                    array.add(child)
                } else {
                    array.add(NSNull())
                }
            }
            return array
        } else {
            if exp && !self.getPriority().isEmpty {
                obj[".priority"] = getPriority().val()
            }
            return obj
        }
    }

    @objc public func dataHash() -> String {
        if let hash = lazyHash {
            return hash
        }
        // STUB: requires FPriorityIndex and FSnapshotUtilities
        let calculatedHash = ""
        lazyHash = calculatedHash
        return calculatedHash
    }

    @objc public func compare(_ other: FNode?) -> ComparisonResult {
        .orderedSame
    }

    @objc public func enumerateChildren(usingBlock block: @escaping (String, FNode, UnsafeMutablePointer<ObjCBool>) -> Void) {

    }

    @objc public func enumerateChildrenReverse(_ reverse: Bool, usingBlock block: @escaping (String, FNode, UnsafeMutablePointer<ObjCBool>) -> Void) {

    }

    @objc public func childEnumerator() -> NSEnumerator? {
        nil
    }

    var children: OrderedDictionary<String, FNode>
    var priorityNode: FNode?
    var lazyHash: String?

    init(children: OrderedDictionary<String, FNode>) {
        self.children = children
    }

    init(
        priority: FNode,
        children: OrderedDictionary<String, FNode>
    ) {
        self.children = children
        self.priorityNode = priority
    }

    @objc public init(
        priority: FNode,
        children: FImmutableSortedDictionary
    ) {
        self.children = children.dict
        self.priorityNode = priority
    }

    @objc public override init() {
        self.children = [:]
        self.priorityNode = nil
    }

    @objc public func enumerateChildrenAndPriority(usingBlock block: @escaping (String, FNode, UnsafeMutablePointer<ObjCBool>) -> Void) {
    }

    @objc public func firstChild() -> FNamedNode? {
        guard let first = children.keys.first else {
            return nil
        }
        return FNamedNode(name: first, andNode: getImmediateChild(first))
    }

    @objc public func lastChild() -> FNamedNode? {
        guard let last = children.keys.last else {
            return nil
        }
        return FNamedNode(name: last, andNode: getImmediateChild(last))
    }
}

@objc public class FMaxNode: FChildrenNode {
    @objc public static var maxNode = FMaxNode()
    public override func compare(_ other: FNode?) -> ComparisonResult {
        if other === self { return .orderedSame }
        else { return .orderedDescending }
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? FMaxNode else { return false }
        return other === self
    }

    public override func getImmediateChild(_ childKey: String) -> FNode {
        FEmptyNode.empty
    }

    // Hmm, is this correct?
    public override var isEmpty: Bool {
        false
    }
}
