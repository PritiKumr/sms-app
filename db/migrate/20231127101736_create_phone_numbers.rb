class CreatePhoneNumbers < ActiveRecord::Migration[7.0]
  def change
    create_table :phone_numbers do |t|
      t.string :number
      t.references :account, null: false, foreign_key: true

      t.timestamps
    end
  end
end
