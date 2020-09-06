Options:Default "trace"

Tasks:clean()

Tasks:minify "minify_server" {
	input = "build/server.lua",
	output = "build/server.min.lua",
}

Tasks:minify "minify_client" {
	input = "build/client.lua",
	output = "build/client.min.lua",
}

Tasks:require "server" {
	include = {"server/*.lua", "shared/*.lua", "vendor/*.lua"},
	startup = "server/bootstrap.lua",
	output = "build/server.lua",
}

Tasks:require "client" {
	include = {"client/*.lua", "shared/*.lua", "vendor/*.lua"},
	startup = "client/bootstrap.lua",
	output = "build/client.lua",
}

Tasks:Task "build" {
    "clean",
    "minify_server",
    "minify_client"
} :Description "Main build task"

Tasks:Default "build"
