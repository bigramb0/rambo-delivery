shared_script '@chumashcokelab/waveshield.lua' --this line was automatically written by WaveShield

fx_version 'cerulean'
games { 'gta5' }

author 'rambo'

client_scripts {"client/*.lua"}
server_scripts {"server/*.lua"}

shared_scripts {'shared/*.lua'}

lua54 'yes'

escrow_ignore {
    'shared/config.lua',
    'shared/routes.lua',
}