local Router = require("lor.lib.router.index")
local middleware = require("lor.lib.middleware.init")
local query = require("lor.lib.middleware.query")
local supported_http_methods = require("lor.lib.methods")


local app = {}

function app:new()
    local instance = {}
    instance.cache = {}
    instance.engines = {}
    instance.settings = {}
    instance.router = Router:new({
        caseSensitive = true,
        strict = true
    })
    -- self.router:use("/", query(), 3)
    -- self.router:use("/", middleware(self), 3)

    setmetatable(instance, {
        __index = self,
        __call = self.handle
    })

    instance:initMethod()
    return instance
end

function app:init()
    self:defaultConfiguration()
end

function app:defaultConfiguration()
    self.locals = {}
    self.mountpath = "/"
    self.locals.settings = self.setttings
end

-- Dispatch a req, res pair into the application. Starts pipeline processing.
-- If no callback is provided, then default error handlers will respond
-- in the event of an error bubbling through the stack.
function app:handle(req, res, callback)
    local router = self.router

    local done = callback or function(req, res)
        return function(err)
            print("&&&&&&&&&&&&&&&&&&&&&&&&finallllll handler")
            res.send(err)
        end
    end

    if not router then
        done()
        return
    end

    router:handle(req, res, done)
end


function app:use(path, fn)
    self:inner_use(3, path, fn)
end


function app:erroruse(path, fn)
    print("application.lua#erroruse")
    self:inner_use(4, path, fn)
end

-- shoule be private
function app:inner_use(fn_args_length, path, fn)
    local router = self.router

    if path and fn and type(path) == "string" and type(fn) == "function" then
        router:use(path, fn, fn_args_length)
    elseif path and not fn then
        if type(path) == "function" then
            fn = path
            path = "/"
            router:use(path, fn, fn_args_length)
        end
    else
        -- todo: error usage
    end

    return self
end

-- Proxy to the app `Router#route()`
-- Returns a new `Route` instance for the _path_.
function app:route(path)
    return self.router:route(path)
end


function app:set(setting, val)
    self.settings[setting] = val
    return self
end



-- Delegate `.VERB(...)` calls to `router.VERB(...)`.
function app:initMethod()
    for http_method, _ in pairs(supported_http_methods) do
        self[http_method] = function(self, path, fn)

            print("\napp:" .. http_method, "start init")
            local route = self.router:route(path)
            route[http_method](route, fn)

            print("app:" .. http_method, "end init\n")
            return self
        end
    end
end


function app:all(path, fn)
    local route = self.router:route(path)

    for http_method, _ in pairs(supported_http_methods) do
        route[http_method](fn)
    end

    return self
end












return app