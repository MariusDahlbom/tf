require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require 'sinatra/reloader'
require 'sinatra/flash'

enable :sessions

get('/') do
  slim(:register)
end

before('/protected/*')do
p "Du behöver logga in"
  if session[:id] == nil
    redirect '/showlogin'
  end
end

get('/logga_ut')do
 session.clear
 redirect '/showlogin'
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
    redirect('/protected/user_products')
  else
    flash[:notice] = "Fel lösen"
    redirect('/showlogin')
  end

  
end

get('/protected/user_products') do
  id = session[:id].to_i
  p id
  db = SQLite3::Database.new('db/dbSlutprojekt2024.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM products WHERE user_id = ?",id)
  slim(:"user_products/index",locals:{product_result:result})

end

post('/users/new') do
  db = SQLite3::Database.new('db/dbSlutprojekt2024.db')
 

  username = params[:name]
  password = params[:password]
  password_confirm = params[:password_confirm]

  result = db.execute("SELECT name FROM users WHERE name=?",username)

  p result
    
    if username == "" || password == "" || password_confirm == ""
        flash[:notice] = "Rutorna måste vara ifyllda"

    elsif result.include?([username])
        flash[:notice] = "Användarnamnet finns redan"

    elsif (password == password_confirm)

      password_digest = BCrypt::Password.create(password)
      db.execute("INSERT INTO users (name,password) VALUES (?,?)",username,password_digest)
      redirect('/')



    else
 
      "Lösenorden matchade inte"
    end
    redirect ('/')

end

get('/protected/products') do
  db = SQLite3::Database.new('db/dbSlutprojekt2024.db')
  db.results_as_hash = true
  result = db.execute("
  SELECT genres.genre_name, products.product_name
  FROM genres
  INNER JOIN products ON products.genre_id = genres.genre_id;
  ")
  
  p result
  slim(:"user_products/index",locals:{product_result:result})

end

get('/protected/products/new') do
  slim(:"user_products/new")
end

post('/protected/products/new') do
  product_name = params[:product_name]
  genre  = params[:genre].to_i
  p "vi fick in datan #{product_name} och #{genre}"
  db = SQLite3::Database.new('db/dbSlutprojekt2024.db')
  db.execute("INSERT INTO products (product_name, genre_id, user_id) VALUES (?,?, ?)", product_name, genre, session[:id])
  redirect('/protected/products')
end

post('/protected/products/:id/delete') do
  p "hej marius"
  id = params[:id].to_i
  db = SQLite3::Database.new('db/dbSlutprojekt2024.db')
  db.execute("DELETE FROM products WHERE product_id = ?",id)
  redirect ('/protected/products')
end

post('/protected/products/:id/update') do
  p "hej Marre"
  id = params[:id].to_i
  product_name = params[:product_name]
  genre_id = params[:genre].to_i
  db = SQLite3::Database.new('db/dbSlutprojekt2024.db')
  db.execute("UPDATE products SET product_name = ?,genre_id = ? WHERE product_id = ?",product_name,genre_id,id)
  redirect('/protected/products')
end

get('/protected/products/:id/edit') do
  p "hej Calle"
  id = params[:id].to_i
  p id
  db = SQLite3::Database.new('db/dbSlutprojekt2024.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM products WHERE product_id = ?", id).first
  p result
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