require 'lpeg'
require 're'
require 'support/utils'

if not arg then arg = {} end
if not arg.debugLevel then arg.debugLevel = 0 end

module( 'parser', package.seeall )

grammar = [[
	Program            <- (<Expression> %nl?)+
	Expression         <- &. -> pushExpr <Space>? (<QuotedExpression> / <UnquotedExpression>)
	QuotedExpression   <- ("'[" <Space>? <Item>? (<Space> <Item>)* <Space>? "]" <Space>?) -> popQuotedExpr
	UnquotedExpression <- ( "[" <Space>? <Item>? (<Space> <Item>)* <Space>? "]" <Space>?) -> popUnquotedExpr
	
	Item           <- (<QuotedSymbol> / <UnquotedSymbol> / <Number> / <String>) / <Expression>
	QuotedSymbol   <- "'" ([a-zA-Z+*\-] [a-zA-Z_+*\-]*) -> pushQuotedSymbol
	UnquotedSymbol <-     ([a-zA-Z+*\-] [a-zA-Z_+*\-]*) -> pushUnquotedSymbol
	Number         <- ( ( [+-]? [0-9] [0-9_]* ('.' [0-9] [0-9_]*)? ) / ( [+-]? '.' [0-9] [0-9_]* ) ) -> pushNumber
	String         <- ( '"' ([^"]* -> pushString) '"' )
	
	Space <- (%s)+
]]

parseFuncs = {}
function parseFuncs.pushExpr()
	table.insert( ast, {} )
end

function parseFuncs.addExpr( inQuotedFlag )
	local node = table.remove( ast )
	node.type = "expression"
	if inQuotedFlag then node.quoted = true end
	if ast[1] then
		table.insert( ast[#ast], node )
	else
		table.insert( ast.program, node )
	end
end

function parseFuncs.popQuotedExpr( )
	parseFuncs.addExpr( true )
end

function parseFuncs.popUnquotedExpr( )
	parseFuncs.addExpr( false )
end

function parseFuncs.addItem( inQuotedFlag, inType, inValue )
	local theItem = {}
	if inQuotedFlag then theItem.quoted = true end
	theItem.type = inType
	theItem.value = inValue
	table.insert( ast[#ast], theItem )
end

function parseFuncs.pushQuotedSymbol( s )
	parseFuncs.addItem( true, "symbol", s )
end

function parseFuncs.pushUnquotedSymbol( s )
	parseFuncs.addItem( false, "symbol", s )
end

function parseFuncs.pushNumber( s )
	parseFuncs.addItem( false, "number", tonumber(s) )
end

function parseFuncs.pushString( s )
	parseFuncs.addItem( false, "string", s )
end

function parseFile( file )
	return parse( io.input(file):read("*a") )
end

function parse( code )
	local ast = parseToAST( code )
	return codeFromAST( ast )
end

function parseToAST( code )
	-- intentionally global; reset on each call
	ast = { program = {} }
	local matchLength = re.compile( grammar, parseFuncs ):match( code )
	if not matchLength or (matchLength < #code) then
		if arg.debugLevel > 0 then
			table.dump( ast )
		end
		error( "Failed to parse code! (Got to around char "..tostring(matchLength).." / "..(#code)..")" )
	end
	return ast.program
end

function codeFromAST( ast )
	error( "TODO: implement codeFromAST" )
end