class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :phone_number
      t.string :password_digest

      t.timestamps
    end
    add_index :users, :phone_number, unique: true
  end
end
