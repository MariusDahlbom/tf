require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require 'sinatra/reloader'

enable :sessions

get('/') do
  slim(:register)
end

get('/showlogin') do
  slim(:login)
end



post('/login') do
  username = params[:name]
  p username
  password = params[:password]
  db = SQLite3::Database.new('db/dbSlutprojekt2024.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM users WHERE name = ?",username).first
  p result
  pwdigest = result["password"]
  id = result["id"]
  p id
  
  if BCrypt::Password.new(pwdigest) == password
    session[:id] = id
    redirect('/user_products')
  else
    "FEL LÖSEN!"
  end
end

get('/user_products') do
  id = session[:id].to_i
  p id
  db = SQLite3::Database.new('db/dbSlutprojekt2024.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM users WHERE id = ?",id)
  slim(:"user_products/index",locals:{product_result:result})
end

post('/users/new') do
  username = params[:name]
  password = params[:password]
  password_confirm = params[:password_confirm]

  if (password == password_confirm)
    #lägg till användare
    password_digest = BCrypt::Password.create(password)
    db = SQLite3::Database.new('db/dbSlutprojekt2024.db')
    db.execute("INSERT INTO users (name,password) VALUES (?,?)",username,password_digest)
    redirect('/')


  else
    #felhantering
    "Lösenorden matchade inte"
  end
end

get('/products') do
  db = SQLite3::Database.new('db/dbSlutprojekt2024.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM products")
  p result
  slim(:"user_products/index",locals:{product_result:result})



end

get('/products/new') do
  slim(:"user_products/new")
end

post('/products/new') do
  product_name = params[:product_name]
  genre  = params[:genre].to_i
  p "vi fick in datan #{product_name} och #{genre}"
  db = SQLite3::Database.new('db/dbSlutprojekt2024.db')
  db.execute("INSERT INTO products (product_name, genre_id) VALUES (?,?)", product_name, genre)
  redirect('/products')
end

post('/products/:id/delete') do
  id = params[:id].to_i
  db = SQLite3::Database.new('db/dbSlutprojekt2024.db')
  db.execute("DELETE FROM products WHERE product_id = ?",id)
  redirect('/products')
end

post('/products/:id/update') do
  id = params[:product_id].to_i
  product_name = params[:product_name]
  genre_id = params[:genre_id].to_i
  db = SQLite3::Database.new('db/dbSlutprojekt2024.db')
  db.execute("UPDATE products SET product_name=?,genre_id=?WHERE product_id = ?",product_name,genre_id,id)
  redirect('/products')
end

get('/products/:id/edit') do
  id = params[:product_id].to_i
  db = SQLite3::Database.new('db/dbSlutprojekt2024.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM products WHERE product_id = ?",id).first
  slim(:"/user_products/edit",locals:{result:result})
end

get('/products/:id') do
  id = params[:product_id].to_i
  db = SQLite3::Database.new('db/dbSlutprojekt2024.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM products WHERE product_id = ?",id).first
  result2 = db.execute("SELECT genre_name FROM genres WHERE genre_id IN (SELECT genre_id FROM products WHERE product_id = ?)",id).first
  p "resultat2 är: #{result2}"
  slim(:"user_products/show",locals:{result:result,result2:result2})
end