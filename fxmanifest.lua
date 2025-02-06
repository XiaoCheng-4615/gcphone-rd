fx_version 'adamant'
games { 'rdr3', 'gta5' }

author 'BTNGaming, chip, ROCKY_southpaw, and Kidz (Original: n3mtv)'
description 'GCPhone for ESX'
version '1.1'


ui_page 'html/dist/index.html'

files {
	'html/dist/index.html',
	'html/dist/static/css/*.css',
	'html/dist/static/js/*.js',


	'html/dist/static/config/config.json',

	-- Coque
	'html/dist/static/img/coque/*.png',
	'html/dist/static/img/coque/*.jpg',

	-- Background
	'html/dist/static/img/background/*.jpg',
	'html/dist/static/img/background/*.png',

	'html/dist/static/img/icons_app/*.png',
	'html/dist/static/img/icons_app/*.jpg',

	'html/dist/static/img/app_bank/*.jpg',
	'html/dist/static/img/app_bank/*.png',

	'html/dist/static/img/app_tchat/*.png',
	'html/dist/static/img/app_tchat/*.jpg',

	'html/dist/static/img/twitter/*.png',
	'html/dist/static/img/twitter/*.jpg',
	'html/dist/static/sound/*.ogg',

	'html/dist/static/img/*.png',
	'html/dist/static/img/*.jpg',
	'html/dist/static/fonts/*.ttf',

	'html/dist/static/sound/*.ogg',
	'html/dist/static/sound/*.mp3',

}

client_script {
    '@es_extended/locale.lua',
    'locales/*.lua',
	"client/esxaddonsgcphone-c.lua",
	"config.lua",
	"client/animation.lua",
	"client/client.lua",

	"client/photo.lua",
	"client/app_tchat.lua",
	"client/bank.lua",
	"client/twitter.lua"
}

server_script {
    '@es_extended/locale.lua',
    'locales/*.lua',
	'@mysql-async/lib/MySQL.lua',
	"server/esxaddonsgcphone-s.lua",
	"config.lua",
	"server/server.lua",

	"server/app_tchat.lua",
	"server/twitter.lua"
}
