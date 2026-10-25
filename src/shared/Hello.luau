-- Módulo compartilhado: pode ser usado tanto pelo servidor quanto pelo cliente.
local Hello = {}

function Hello.saudar(nome: string): string
	return `Olá, {nome}!`
end

return Hello
