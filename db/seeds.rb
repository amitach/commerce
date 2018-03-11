# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

[Product, User, Cart, CartProduct, Order].each do |model|
  model.destroy_all
end

user = User.create!(name: 'John Doe', email: 'johndoe@example.com')
product1 = Product.create!(price: 10, name: 'Foo')
product2 = Product.create!(price: 20, name: 'Bar')

cart = Cart.create!(user: user)

CartProduct.create!(product: product1, cart: cart, quantity: 3)
CartProduct.create!(product: product2, cart: cart, quantity: 2)
Order.create!(cart: cart, shipping_method: 'ground')
