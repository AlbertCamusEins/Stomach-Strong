# scripts/Recipe.gd
@tool
class_name Recipe extends Resource

@export_group("基本信息")
@export var recipe_name: String
@export_multiline var description: String

@export_group("制作需求")
# 这里我们使用刚刚创建的 IngredientRequirement 资源数组
@export var ingredients: Array[IngredientRequirement]
@export var required_technique: CookingTechnique
@export var required_cookware: Item

@export_group("产出")
@export var output_item: Item   # 最终产出的菜品 (也是一个 Item 资源)
@export var output_quantity: int = 1 # 产出数量

# (可选) 可以在这里添加烹饪时间等其他属性
@export_group("其他")
@export var cooking_time: float = 5.0 # 单位：秒
