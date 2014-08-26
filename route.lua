local routes = _G.routes

if routes == nil then
  routes = {}
  ngx.log(ngx.ALERT, "Rota não está no cache.")
end

local route = routes[ngx.var.http_host]

if route == nil then
  local redis = require "resty.redis"
  local client = redis:new()

  client:set_timeout(1000) -- 1 segundo

  local ok, err = client:connect("127.0.0.1", 6379)
  if not ok then
    ngx.log(ngx.ERR, "Falha ao conectar no redis", err)
    return ngx.exit(500)
  end

  ok, err = client:set(ngx.var.http_host, "127.0.0.1:3006/test")
  if not ok then
    ngx.log(ngx.ERR, "Falha ao configurar a chave ngx.var.http_host no redis", err)
  end

  route, err = client:get(ngx.var.http_host)
  if not ok then
    ngx.log(ngx.ERR, "Falha ao retornar o valor da chave ngx.var.http_host no redis", err)
    return ngx.exit(500)
  end

  ok, err = client:close()
  if not ok then
    ngx.log(ngx.ERR, "Falha ao fechar a conexão com o redis")
    return ngx.exit(500)
  end
end

if route ~= nil then
  ngx.log(ngx.ALERT, "ngx.var.http_host: ", route)
  ngx.var.new_route = route
  routes[ngx.var.http_host] = route
  _G.routes = routes
else
  return ngx.exit(404)
end
