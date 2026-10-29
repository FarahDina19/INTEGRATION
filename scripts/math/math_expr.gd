class_name MathExpr
extends RefCounted
## Parses student-style maths ("2x^3 + 5x + C", "ln|x+1|", "-1/2 cos(2x)", "xe^x")
## into a small AST and evaluates it numerically. Implicit multiplication is supported.

const FUNCTIONS := ["arcsin", "arccos", "arctan", "sqrt", "sin", "cos", "tan", "sec", "csc", "cot", "exp", "abs", "ln", "log"]

var error := ""
var _tokens: Array = []
var _pos := 0


## Returns {"ok": bool, "ast": Variant, "error": String, "uses_x": bool, "uses_c": bool}.
static func parse(source: String) -> Dictionary:
	var parser := MathExpr.new()
	return parser._parse(source)


static func evaluate(ast: Variant, x: float, c_value: float = 0.0) -> float:
	if ast == null:
		return NAN
	return _eval(ast, x, c_value)


static func normalize(source: String) -> String:
	var text := source.strip_edges()
	var swaps := {
		"−": "-", "–": "-", "—": "-", "×": "*", "·": "*", "÷": "/", "π": "pi",
		"ˣ": "^x", "²": "^2", "³": "^3", "⁴": "^4", "⁵": "^5", "⁶": "^6", "√": "sqrt", "**": "^",
		"[": "(", "]": ")", "{": "(", "}": ")",
	}
	for key: String in swaps:
		text = text.replace(key, swaps[key])
	return text


func _parse(source: String) -> Dictionary:
	error = ""
	_tokens = []
	_pos = 0
	var text := normalize(source)
	if text.is_empty():
		return _fail("Type an answer first.")
	if not _tokenize(text):
		return _fail(error)
	var ast: Variant = _expression()
	if not error.is_empty():
		return _fail(error)
	if _pos < _tokens.size():
		var leftover: Dictionary = _tokens[_pos]
		return _fail("I could not understand “%s” here." % str(leftover.get("v", "")))
	var flags := {"x": false, "c": false}
	_scan(ast, flags)
	return {"ok": true, "ast": ast, "error": "", "uses_x": flags.x, "uses_c": flags.c}


func _fail(message: String) -> Dictionary:
	return {"ok": false, "ast": null, "error": message, "uses_x": false, "uses_c": false}


func _scan(node: Variant, flags: Dictionary) -> void:
	if not node is Array:
		return
	var n: Array = node
	match str(n[0]):
		"var":
			if str(n[1]) == "x":
				flags.x = true
			elif str(n[1]) == "C":
				flags.c = true
		_:
			for index: int in range(1, n.size()):
				_scan(n[index], flags)


func _tokenize(text: String) -> bool:
	var i := 0
	var lower := text.to_lower()
	while i < text.length():
		var ch := text[i]
		if ch == " " or ch == "\t":
			i += 1
			continue
		if ch.is_valid_int() or ch == ".":
			var start := i
			while i < text.length() and (text[i].is_valid_int() or text[i] == "."):
				i += 1
			var literal := text.substr(start, i - start)
			if literal.count(".") > 1 or literal == ".":
				error = "The number “%s” looks odd." % literal
				return false
			_tokens.append({"t": "num", "v": literal.to_float()})
			continue
		if "+-*/^()|,".contains(ch):
			_tokens.append({"t": "op", "v": ch})
			i += 1
			continue
		if _is_letter(ch):
			var matched := false
			for name: String in FUNCTIONS:
				if lower.substr(i, name.length()) == name:
					_tokens.append({"t": "fn", "v": "ln" if name == "log" else name})
					i += name.length()
					matched = true
					break
			if matched:
				continue
			if lower.substr(i, 2) == "pi":
				_tokens.append({"t": "num", "v": PI})
				i += 2
				continue
			if lower.substr(i, 2) == "dx":
				# Students sometimes copy "dx"; ignore it.
				i += 2
				continue
			match ch:
				"x", "X":
					_tokens.append({"t": "var", "v": "x"})
				"e":
					_tokens.append({"t": "num", "v": exp(1.0)})
				"C", "c", "K", "k":
					_tokens.append({"t": "var", "v": "C"})
				_:
					error = "Use x as the variable. I don't know “%s”." % ch
					return false
			i += 1
			continue
		error = "I don't know the symbol “%s”." % ch
		return false
	return true


static func _is_letter(ch: String) -> bool:
	var code := ch.unicode_at(0)
	return (code >= 65 and code <= 90) or (code >= 97 and code <= 122)


func _peek() -> Dictionary:
	return _tokens[_pos] if _pos < _tokens.size() else {}


func _is_op(value: String) -> bool:
	var token := _peek()
	return token.get("t", "") == "op" and token.get("v", "") == value


func _expression() -> Variant:
	var left: Variant = _term()
	while error.is_empty() and (_is_op("+") or _is_op("-")):
		var op: String = _peek().v
		_pos += 1
		var right: Variant = _term()
		left = ["+" if op == "+" else "-", left, right]
	return left


func _starts_factor() -> bool:
	var token := _peek()
	if token.is_empty():
		return false
	match str(token.t):
		"num", "var", "fn":
			return true
		"op":
			return token.v == "("
	return false


func _term() -> Variant:
	var left: Variant = _unary()
	while error.is_empty():
		if _is_op("*") or _is_op("/"):
			var op: String = _peek().v
			_pos += 1
			var right: Variant = _unary()
			left = [op, left, right]
		elif _starts_factor():
			# Implicit multiplication: 2x, x(x+1), 3sin(x), xe^x
			var right_implicit: Variant = _power()
			left = ["*", left, right_implicit]
		else:
			break
	return left


func _unary() -> Variant:
	if _is_op("-"):
		_pos += 1
		return ["neg", _unary()]
	if _is_op("+"):
		_pos += 1
		return _unary()
	return _power()


func _power() -> Variant:
	var base: Variant = _primary()
	if error.is_empty() and _is_op("^"):
		_pos += 1
		var exponent: Variant = _unary()
		return ["^", base, exponent]
	return base


func _primary() -> Variant:
	var token := _peek()
	if token.is_empty():
		error = "Your answer ends too early — something is missing."
		return null
	_pos += 1
	match str(token.t):
		"num":
			return ["num", float(token.v)]
		"var":
			return ["var", str(token.v)]
		"fn":
			var name: String = token.v
			var power_after: Variant = null
			if _is_op("^"):
				# sin^2(x) style
				_pos += 1
				power_after = _primary()
			var argument: Variant
			if _is_op("(") or _is_op("|"):
				argument = _primary()
			else:
				argument = _power()
				# "sin 2x" means sin(2x); "ln x + 1" stays ln(x) + 1.
				while error.is_empty() and not _peek().is_empty() and str(_peek().t) in ["num", "var"]:
					argument = ["*", argument, _power()]
			var call: Variant = ["fn", name, argument]
			return ["^", call, power_after] if power_after != null else call
		"op":
			if token.v == "(":
				var inner: Variant = _expression()
				if not _is_op(")"):
					if error.is_empty():
						error = "A bracket “(” is not closed."
					return null
				_pos += 1
				return inner
			if token.v == "|":
				var inside: Variant = _expression()
				if not _is_op("|"):
					if error.is_empty():
						error = "An absolute-value bar “|” is not closed."
					return null
				_pos += 1
				return ["fn", "abs", inside]
	error = "I didn't expect “%s” there." % str(token.v)
	return null


static func _eval(node: Variant, x: float, c_value: float) -> float:
	var n: Array = node
	match str(n[0]):
		"num":
			return float(n[1])
		"var":
			return x if str(n[1]) == "x" else c_value
		"neg":
			return -_eval(n[1], x, c_value)
		"+":
			return _eval(n[1], x, c_value) + _eval(n[2], x, c_value)
		"-":
			return _eval(n[1], x, c_value) - _eval(n[2], x, c_value)
		"*":
			return _eval(n[1], x, c_value) * _eval(n[2], x, c_value)
		"/":
			var denominator := _eval(n[2], x, c_value)
			if absf(denominator) < 1e-12:
				return NAN
			return _eval(n[1], x, c_value) / denominator
		"^":
			var b := _eval(n[1], x, c_value)
			var p := _eval(n[2], x, c_value)
			if b < 0.0 and absf(p - roundf(p)) > 1e-9:
				return NAN
			return pow(b, p)
		"fn":
			var v := _eval(n[2], x, c_value)
			match str(n[1]):
				"sin": return sin(v)
				"cos": return cos(v)
				"tan": return tan(v)
				"sec": return 1.0 / cos(v)
				"csc": return 1.0 / sin(v)
				"cot": return cos(v) / sin(v)
				"exp": return exp(v)
				"abs": return absf(v)
				"sqrt": return sqrt(v) if v >= 0.0 else NAN
				"ln": return log(v) if v > 0.0 else NAN
				"arcsin": return asin(v)
				"arccos": return acos(v)
				"arctan": return atan(v)
	return NAN
