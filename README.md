# LXUUID

该方案是由openUUID方案精简而来，同样是为了充当iOS设备的唯一标识

该方案获取uuid的顺序如下：
1. 检查内存缓存
2. 检查UserDefaults中的缓存
3. 检查剪切板中的缓存


