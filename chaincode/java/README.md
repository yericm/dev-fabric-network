本链码为测试用链码, 包含两个方法 put, get

```
用法: <get/put> <keys> [value]

示例:

获取 "a" 对应的值
get "a"

获取 复杂键 "a b c" 对应的值
get "a, b, c"

为 "a" 设置值
put "a" "aValue"

为 复杂键 "a b c" 设置值
put "a, b, c" "compositeKeyValue"
```

