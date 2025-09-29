# scripts/InitialInventorySlot.gd
# 这是一个专门用于在编辑器中设置初始物品栏的数据容器
@tool
class_name InventorySlot extends Resource

# 提供两个清晰的导出变量，以便在检查器中设置
@export var item: Item
@export var quantity: int = 1
