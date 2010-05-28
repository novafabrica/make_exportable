ActiveRecord::Schema.define :version => 0 do
  
  create_table :users, :force => true do |t|
    t.string :first_name, :last_name, :password, :email
    t.boolean :is_admin
    t.timestamps
  end

  create_table :posts, :force => true do |t|
    t.string :title
    t.text :content
    t.boolean :approved
    t.timestamps
  end

end
