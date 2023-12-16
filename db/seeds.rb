# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

Assistant.create(
  [
    { external_id: "asst_4sFBhJnj82G1cLaOZD9Qszsm",
      name: "助理小唐",
      model: "gpt-3.5-turbo-1106",
      instructions: "你是知识星球「唐韧的产品星球」的助理，请帮助唐韧解答知识星球成员的问题。同时再帮助唐韧总结并整理每天星球的动态，帮助唐韧更好地理解自己的用户。"
    },
  ]
)
