class AddAddressFields < ActiveRecord::Migration
  def self.up
    change_table :addresses do |t|
      t.column :number, :string, :size => 8
      t.column :borough, :string
      t.column :area_code, :string, :size => 2
    end
  end

  def self.down
    remove_column :addresses, :number
    remove_column :addresses, :borough
    remove_column :addresses, :area_code
  end
end
