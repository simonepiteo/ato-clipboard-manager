struct ReleasePagination {
    static let pageSize = 10

    let pageIndex: Int
    let pageCount: Int
    let itemRange: Range<Int>

    init(itemCount: Int, pageIndex: Int) {
        let count = max(0, itemCount)
        pageCount = max(1, count / Self.pageSize + (count % Self.pageSize == 0 ? 0 : 1))
        self.pageIndex = min(max(0, pageIndex), pageCount - 1)
        let start = self.pageIndex * Self.pageSize
        itemRange = start..<min(start + Self.pageSize, count)
    }
}
