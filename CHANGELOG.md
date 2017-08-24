
## CHANGE LOG

### v1.1.5

- 解决未定义的 qiniu_delete_after_days 和 qiniu_persistent_pipeline 方法错误

https://github.com/huobazi/carrierwave-qiniu/pull/81/

### v1.1.4

- 支持带样式的私有链接

https://github.com/huobazi/carrierwave-qiniu/pull/80

### v1.1.3

新增参数 qiniu_delete_after_days

参考: https://developer.qiniu.com/kodo/api/1732/update-file-lifecycle

### v1.1.2

Fix:
https://github.com/huobazi/carrierwave-qiniu/pull/79

### v1.1.1

https://github.com/huobazi/carrierwave-qiniu/pull/78

### v1.1.0

- Require carrierwave ~> 1.0
 
https://github.com/huobazi/carrierwave-qiniu/pull/73

### v1.0.1

- 使用 module ClassMethods 以兼容 Rails4

https://github.com/huobazi/carrierwave-qiniu/issues/71

https://github.com/huobazi/carrierwave-qiniu/pull/72

### v1.0.0

- 变更图片样式的用法
https://github.com/huobazi/carrierwave-qiniu/pull/70

- 不兼容上一版本

``` qiniu_styles ``` 移动到 config 中
在 uploader 内 使用 ``` use_qiniu_styles ``` 来指定使用默认 styles 或者 覆盖默认配置
详见 ReadMe 中的示例

### v0.2.6

- 提供图片样式的便利方法
https://github.com/huobazi/carrierwave-qiniu/pull/68


### v0.2.5

https://github.com/huobazi/carrierwave-qiniu/pull/61

https://github.com/huobazi/carrierwave-qiniu/pull/62


### v0.2.4

- Add test for upload failed
https://github.com/huobazi/carrierwave-qiniu/pull/57

### v0.2.3

- Add extension method
https://github.com/huobazi/carrierwave-qiniu/pull/50

### v0.2.2

- 增加对七牛SDK中复制图片功能的支持
https://github.com/huobazi/carrierwave-qiniu/pull/49

### v0.2.1

- 增加
```
    qiniu_callback_url
    qiniu_callback_body
    qiniu_can_overwrite
```

https://github.com/huobazi/carrierwave-qiniu/pull/47

### v0.2.0

- 升级七牛 SDK 至 6.5.1

### v0.1.8.2

https://github.com/huobazi/carrierwave-qiniu/pull/42

### v0.1.8.1

https://github.com/huobazi/carrierwave-qiniu/pull/36

https://github.com/huobazi/carrierwave-qiniu/pull/38

### v0.1.7

- 添加从云端读取（下载）文件  。 [https://github.com/huobazi/carrierwave-qiniu/pull/27](https://github.com/huobazi/carrierwave-qiniu/pull/27)

- 增加获取有时效性url链接地址的方法 。 [https://github.com/huobazi/carrierwave-qiniu/issues/25](https://github.com/huobazi/carrierwave-qiniu/issues/25)

- 升级七牛 SDK 至 6.4.2
