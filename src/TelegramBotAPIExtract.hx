package ;
import haxe.Http;
import haxe.Template;
import sys.io.File;

using TelegramBotAPIExtract;
using StringTools;

class TelegramBotAPIExtract {

	private static var apiStart:EReg = ~/<h3>.+>Getting updates<\/h3>/;
	private static var header:EReg = ~/<h4>.+>(\S+)<\/h4>/;
	private static var table:EReg = ~/<table.+>/;
	private static var tableEnd:EReg = ~/<\/table>/;
	private static var row:EReg = ~/<tr>/;
	private static var rowEnd:EReg = ~/<\/tr>/;
	private static var cell:EReg = ~/<td>(.+)<\/td>/;
	private static var returns:EReg = ~/<p>(.*return(s|ed).*)<\/p>/i;

	private static var fields:Array<Field> = [];
	private static var field:Field;
	private static var param:Array<String>;
	
	private static var apiContext:APIContext = { methods:[], typeDefs:[] };

	public static function main():Void {
		fromApiStart('https://core.telegram.org/bots/api'.getLinesFromURL());
		File.saveContent('src/TelegramBotAPI.hx', new Template(File.getContent('src/TelegramBotAPI.hxt')).execute(apiContext));
	}

	public static function getLinesFromURL(url:String):Lines {
		var http:Http = new Http(url);
		http.request();
		return new Lines(http.responseData.split('\n'));
	}

	private static function checkField():Void {
		if (field != null) {
			switch (field.name.isMethod()) {
				case true: apiContext.methods.push(getMethod(field));
				default: apiContext.typeDefs.push(getTypedef(field));
			}
		}
	}

	public static function getMethod(field:Field):Method {
		var params:Array<MethodArg> = [];
		for (param in field.params) {
			switch (param) {
				case [n, t, o, _]: params.push({
					name:n, optional:o.isOptional(), type:t.getType()
				});
				default:
			}
		}
		return { name:field.name, paramsName:field.name.getParamsName(), params:params, returns:field.returns.getType() };
	}

	public static function getTypedef(field:Field):TypeDef {
		var vars:Array<TypeDefVar> = [];
		for (param in field.params) {
			switch (param) {
				case [n, t, o]: vars.push({ name:n, optional:o.isOptional(), type:t.getType() });
			}
		}
		return { name:field.name, vars:vars };
	}

	public static function fromApiStart(lines:Lines):Void {
		while (lines.next()) if (apiStart.matches(lines)) fromHeader(lines);
		checkField();
	}

	public static function fromHeader(lines:Lines):Void {
		while (lines.next()) {
			if (header.matches(lines)) {
				checkField();
				fields.push(field = { name:header.first(), params:[], returns:null });
				fromHeader(lines);
			} else if (returns.matches(lines)) {
				field.returns = returns.first().getReturns();
			} else if (table.matches(lines)) {
				while (lines.next()) if (rowEnd.matches(lines)) fromRow(lines);
			}
		}
	}

	public static function fromRow(lines:Lines):Void {
		while (lines.next()) {
			if (tableEnd.matches(lines)) {
				fromHeader(lines);
				return;
			} else if (row.matches(lines)) {
				field.params.push(param = []);
				fromCell(lines, param);
			}
		}
	}

	public static function fromCell(lines:Lines, param:Array<String>):Void {
		while (lines.next()) {
			if (rowEnd.matches(lines)) {
				fromRow(lines);
				return;
			} else if (cell.matches(lines)) param.push(cell.first());
		}
	}

	public static inline function matches(e:EReg, l:Lines):Bool {
		var s:String = l.current();
		return s == null || s.length == 0 ? false : e.match(s);
	}

	public static inline function first(e:EReg):String {
		return e.matched(1);
	}

	public static inline function second(e:EReg):String {
		return e.matched(2);
	}

	public static inline function isMethod(name:String):Bool {
		return name.charAt(0).toLowerCase() == name.charAt(0);
	}

	public static inline function isOptional(optional:String):Bool {
		return optional.indexOf('Optional') >= 0;
	}

	public static inline function getType(s:String):String {
		if (s == null || s.length == 0) return 'Void';
		var arrayOfReg:EReg = ~/Array of (.+)/;
		var linkReg:EReg = ~/<a.+>(.+)<\/a>/;
		var orReg:EReg = ~/(.+) or (.+)/;
		return switch (s) {
			case 'Integer': 'Int';
			case 'Boolean', 'True', 'False', 'true', 'false': 'Bool';
			case 'Float number': 'Float';
			case s if (orReg.match(s)):
				'EitherType<${getType(orReg.first())}, ${getType(orReg.second())}>';
			case s if (arrayOfReg.match(s)):
				'Array<${getType(arrayOfReg.first())}>';
			case s if (linkReg.match(s)): linkReg.first();
			default: s;
		}
	}

	public static inline function getParamsName(name:String):String {
		return name.charAt(0).toUpperCase() + name.substring(1) + 'Params';
	}

	public static inline function getReturns(r:String):String {
		var returnEither:EReg = ~/otherwise/i;
		var returnArrayOf:EReg = ~/[A|a]rray.+of.+<a.+>(.+)<\/a>/;
		var returnStartLink:EReg = ~/(?:[R|r]eturns).*<a.+>([A-Z][a-zA-Z]+)<\/a>/;
		var returnEndLink:EReg = ~/<a.+>([A-Z][a-zA-Z]+)<\/a>.+(?:returned)/;
		var returnsStartType:EReg = ~/[R|r]eturns.+(True|False|String|Int)/;
		var returnsEndType:EReg = ~/(True|False|String|Int).+returned/;
		return switch(r) {
			case r if (returnEither.match(r)):
				'${ returnEither.matchedLeft().getReturns() } or ${ returnEither.matchedRight().getReturns() }';
			case r if (returnArrayOf.match(r)): 'Array<${ returnArrayOf.first().replaceLinkNames() }>';
			case r if (returnStartLink.match(r)): returnStartLink.first().replaceLinkNames();
			case r if (returnEndLink.match(r)): returnEndLink.first().replaceLinkNames();
			case r if (returnsStartType.match(r)): returnsStartType.first();
			case r if (returnsEndType.match(r)): returnsEndType.first();
			default: 'Void';
		};
	}

	public static inline function replaceLinkNames(link:String):String {
		return switch (link) { case "Messages": "Message"; default: link; };
	}

	#if idea // IntelliJ IDEA fix
	public static var n:String;
	public static var t:String;
	public static var o:String;
	public static var d:String;
	public static var _;
	#end
}

private typedef APIContext = {
	var methods:Array<Method>;
	var typeDefs:Array<TypeDef>;
}

private typedef Method = {
	var name:String;
	var paramsName:String;
	var params:Array<MethodArg>;
	var returns:String;
}

private typedef MethodArg = {
	var name:String;
	var optional:Bool;
	var type:String;
}

private typedef TypeDef = {
	var name:String;
	var vars:Array<TypeDefVar>;
}

private typedef TypeDefVar = {
	var name:String;
	var optional:Bool;
	var type:String;
}

private typedef Field = {
	var name:String;
	var params:Array<Array<String>>;
	var returns:String;
}

class Lines {

	private var array:Array<String>;
	public var index:Int;

	public function new(array:Array<String>) {
		this.array = array;
		index = -1;
	}

	public function next():Bool {
		return index++ < array.length;
	}

	public function current():String {
		return array[index];
	}
}