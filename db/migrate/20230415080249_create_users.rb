class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :name
      t.string :firebase_uid, unique: true
      t.string :image

      t.timestamps
    end
  end
end
