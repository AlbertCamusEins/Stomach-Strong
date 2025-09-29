# scripts/CookingTechnique.gd
# 定义一种烹饪技巧资源
@tool
class_name CookingTechnique extends Resource

@export_group("basic info")
@export var technique_name: String  # 技巧名称，例如：“炖煮”
@export_multiline var description: String # 技巧的描述
