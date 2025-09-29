# scripts/IngredientRequirement.gd
@tool
class_name IngredientRequirement extends Resource

# 这个脚本定义了菜谱中对单一食材的需求

@export var item: Item       # 需要的食材 (Item 资源)
@export var quantity: int = 1 # 需要的数量
