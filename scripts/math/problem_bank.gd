class_name ProblemBank
extends RefCounted
## Randomised integration challenges matching Unit 3 (DUM10092): reverse differentiation,
## basic rules, substitution, integration by parts, partial fractions and definite integrals.

const TOPICS := [
	{"id": "reverse", "name": "Reverse Differentiation", "short": "Reverse", "coins": 8, "xp": 10,
		"blurb": "Find the function whose derivative you are given."},
	{"id": "rules", "name": "Basic Integration Rules", "short": "Rules", "coins": 10, "xp": 12,
		"blurb": "Power rule, eˣ, 1/x and trig integrals."},
	{"id": "sub", "name": "Substitution", "short": "Substitution", "coins": 14, "xp": 15,
		"blurb": "Spot an inner function u and its derivative."},
	{"id": "parts", "name": "Integration by Parts", "short": "By Parts", "coins": 18, "xp": 18,
		"blurb": "∫u dv = uv − ∫v du, choosing u with LIATE."},
	{"id": "pf", "name": "Partial Fractions", "short": "Partial Fractions", "coins": 18, "xp": 18,
		"blurb": "Split a rational function, then integrate to logs."},
	{"id": "definite", "name": "Definite Integrals", "short": "Definite", "coins": 12, "xp": 14,
		"blurb": "Evaluate F(b) − F(a) to get a number."},
]

const SAMPLE_XS := [0.35, 0.7, 1.1, 1.45, 1.9, 2.3]
const SUPERSCRIPT := {"0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴", "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹", "-": "⁻"}
const SUBSCRIPT := {"0": "₀", "1": "₁", "2": "₂", "3": "₃", "4": "₄", "5": "₅", "6": "₆", "7": "₇", "8": "₈", "9": "₉", "-": "₋"}


static func topic(id: String) -> Dictionary:
	for entry: Dictionary in TOPICS:
		if entry.id == id:
			return entry
	return TOPICS[0]


static func topic_ids() -> Array:
	var ids: Array = []
	for entry: Dictionary in TOPICS:
		ids.append(entry.id)
	return ids


# ---------------------------------------------------------------- formatting helpers

static func sup(value: Variant) -> String:
	var text := str(value)
	var out := ""
	for ch in text:
		out += SUPERSCRIPT.get(ch, ch)
	return out


static func sub_script(value: Variant) -> String:
	var text := str(value)
	var out := ""
	for ch in text:
		out += SUBSCRIPT.get(ch, ch)
	return out


static func gcd(a: int, b: int) -> int:
	a = absi(a)
	b = absi(b)
	while b != 0:
		var t := b
		b = a % b
		a = t
	return maxi(a, 1)


## x-power body for display: n=0 → "", n=1 → "x", n=3 → "x³"
static func xpow(n: int) -> String:
	if n == 0:
		return ""
	if n == 1:
		return "x"
	return "x" + sup(n)


## Signed fraction coefficient attached to a body: (3,4,"x⁴") → "3x⁴/4"; (-1,1,"x") → "−x"; (5,1,"") → "5"
static func coef(num: int, den: int, body: String) -> String:
	if num == 0:
		return "0"
	var g := gcd(num, den)
	num /= g
	den /= g
	if den < 0:
		den = -den
		num = -num
	var sign := "−" if num < 0 else ""
	var n := absi(num)
	var lead := ""
	if body.is_empty():
		lead = str(n)
	elif n == 1:
		lead = body
	else:
		lead = str(n) + body
	return sign + lead + ("" if den == 1 else "/" + str(den))


## Join display terms with proper + / − separators.
static func join_terms(terms: Array) -> String:
	var out := ""
	for raw: Variant in terms:
		var term := str(raw)
		if term.is_empty() or term == "0":
			continue
		if out.is_empty():
			out = term
		elif term.begins_with("−"):
			out += " − " + term.substr(1)
		else:
			out += " + " + term
	return "0" if out.is_empty() else out


## Parseable fraction text "(3/4)" or "3".
static func frac(num: int, den: int) -> String:
	var g := gcd(num, den)
	num /= g
	den /= g
	if den < 0:
		den = -den
		num = -num
	return str(num) if den == 1 else "(%d/%d)" % [num, den]


static func signed_linear(p: int, q: int) -> String:
	return join_terms([coef(p, 1, "x"), coef(q, 1, "")])


static func pick(rng: RandomNumberGenerator, values: Array) -> Variant:
	return values[rng.randi_range(0, values.size() - 1)]


static func nonzero(rng: RandomNumberGenerator, low: int, high: int) -> int:
	var value := 0
	while value == 0:
		value = rng.randi_range(low, high)
	return value


static func integral(body: String, lower: String = "", upper: String = "") -> Dictionary:
	return {"body": body, "lower": lower, "upper": upper}


static func plain_integral(spec: Dictionary) -> String:
	if str(spec.get("lower", "")).is_empty():
		return "∫ " + str(spec.body)
	return "∫ from %s to %s of %s" % [spec.lower, spec.upper, spec.body]


# ---------------------------------------------------------------- generators

static func generate(topic_id: String, rng: RandomNumberGenerator) -> Dictionary:
	var problem: Dictionary
	match topic_id:
		"reverse": problem = _reverse(rng)
		"rules": problem = _rules(rng)
		"sub": problem = _substitution(rng)
		"parts": problem = _parts(rng)
		"pf": problem = _partial_fractions(rng)
		"definite": problem = _definite(rng)
		_: problem = _rules(rng)
	var info := topic(topic_id)
	problem["topic"] = info.id
	problem["topic_name"] = info.name
	problem["coins"] = int(info.coins)
	problem["xp"] = int(info.xp)
	if not problem.has("kind"):
		problem["kind"] = "indefinite"
	if not problem.has("integral"):
		problem["integral"] = {}
	return problem


static func _reverse(rng: RandomNumberGenerator) -> Dictionary:
	var variant := rng.randi_range(0, 4)
	if variant <= 2:
		var n := rng.randi_range(1, 4)
		var k := rng.randi_range(2, 6)
		var c := k * (n + 1)
		var prime := coef(c, 1, xpow(n))
		var ans := coef(k, 1, xpow(n + 1))
		return {
			"lead": "F′(x) = %s.  Find F(x)." % prime,
			"integrand": "%d*x^%d" % [c, n],
			"answer": "%d*x^%d" % [k, n + 1],
			"answer_display": ans + " + C",
			"hints": [
				"Ask: which function, when differentiated, gives %s?" % prime,
				"Differentiating xⁿ⁺¹ gives (n + 1)xⁿ, so the answer contains %s." % xpow(n + 1),
				"Raise the power %d → %d, then divide %d by %d." % [n, n + 1, c, n + 1],
			],
			"steps": [
				"Reverse the power rule: raise the power of x from %d to %d." % [n, n + 1],
				"Divide the coefficient by the new power: %d ÷ %d = %d." % [c, n + 1, k],
				"Check by differentiating: d/dx(%s) = %s ✓" % [ans, prime],
				"Add the constant of integration: F(x) = %s + C" % ans,
			],
		}
	var k2 := rng.randi_range(2, 4)
	if variant == 3:
		return {
			"lead": "F′(x) = %dcos(%dx).  Find F(x)." % [k2, k2],
			"integrand": "%d*cos(%d*x)" % [k2, k2],
			"answer": "sin(%d*x)" % k2,
			"answer_display": "sin(%dx) + C" % k2,
			"hints": [
				"Which trig function differentiates to a cosine?",
				"d/dx[sin(kx)] = k·cos(kx) by the chain rule.",
				"Try sin(%dx) and differentiate it to check." % k2,
			],
			"steps": [
				"Recall d/dx[sin(kx)] = k·cos(kx).",
				"Here k = %d, so d/dx[sin(%dx)] = %dcos(%dx) ✓" % [k2, k2, k2, k2],
				"F(x) = sin(%dx) + C" % k2,
			],
		}
	return {
		"lead": "F′(x) = %de^(%dx).  Find F(x)." % [k2, k2],
		"integrand": "%d*e^(%d*x)" % [k2, k2],
		"answer": "e^(%d*x)" % k2,
		"answer_display": "e^(%dx) + C" % k2,
		"hints": [
			"Exponentials stay exponentials when you differentiate them.",
			"d/dx[e^(kx)] = k·e^(kx).",
			"Try e^(%dx) and differentiate it to check." % k2,
		],
		"steps": [
			"Recall d/dx[e^(kx)] = k·e^(kx).",
			"With k = %d: d/dx[e^(%dx)] = %de^(%dx) ✓" % [k2, k2, k2, k2],
			"F(x) = e^(%dx) + C" % k2,
		],
	}


static func _rules(rng: RandomNumberGenerator) -> Dictionary:
	var variant := rng.randi_range(0, 3)
	match variant:
		0:
			var n := rng.randi_range(2, 4)
			var m := rng.randi_range(1, n - 1)
			var p := rng.randi_range(1, 3)
			var q := nonzero(rng, -3, 3)
			var c := nonzero(rng, -7, 9)
			var a := p * (n + 1)
			var b := q * (m + 1)
			var body := join_terms([coef(a, 1, xpow(n)), coef(b, 1, xpow(m)), coef(c, 1, "")])
			var ans := join_terms([coef(p, 1, xpow(n + 1)), coef(q, 1, xpow(m + 1)), coef(c, 1, "x")])
			return {
				"lead": "Integrate with respect to x.",
				"integral": integral("(%s) dx" % body),
				"integrand": "%d*x^%d + %d*x^%d + %d" % [a, n, b, m, c],
				"answer": "%d*x^%d + %d*x^%d + %d*x" % [p, n + 1, q, m + 1, c],
				"answer_display": ans + " + C",
				"hints": [
					"Integrate term by term: ∫(f + g) dx = ∫f dx + ∫g dx.",
					"Power rule: ∫xⁿ dx = xⁿ⁺¹/(n + 1). A constant k integrates to kx.",
					"First term: %s → %s." % [coef(a, 1, xpow(n)), coef(p, 1, xpow(n + 1))],
				],
				"steps": [
					"Split into three integrals and use ∫xⁿ dx = xⁿ⁺¹/(n + 1).",
					"∫%s dx = %s" % [coef(a, 1, xpow(n)), coef(p, 1, xpow(n + 1))],
					"∫%s dx = %s" % [coef(b, 1, xpow(m)), coef(q, 1, xpow(m + 1))],
					"∫%s dx = %s" % [coef(c, 1, ""), coef(c, 1, "x")],
					"Combine: %s + C" % ans,
				],
			}
		1:
			var k := rng.randi_range(2, 4)
			var p2 := rng.randi_range(1, 3)
			var a2 := k * p2
			var ans2 := coef(p2, 1, "e^(%dx)" % k)
			return {
				"lead": "Integrate with respect to x.",
				"integral": integral("%s dx" % coef(a2, 1, "e^(%dx)" % k)),
				"integrand": "%d*e^(%d*x)" % [a2, k],
				"answer": "%d*e^(%d*x)" % [p2, k],
				"answer_display": ans2 + " + C",
				"hints": [
					"∫e^(kx) dx = e^(kx)/k + C.",
					"Keep the constant %d outside the integral." % a2,
					"%d ÷ %d = %d." % [a2, k, p2],
				],
				"steps": [
					"Take the constant out: %d∫e^(%dx) dx." % [a2, k],
					"∫e^(%dx) dx = e^(%dx)/%d." % [k, k, k],
					"%d · e^(%dx)/%d = %s" % [a2, k, k, ans2],
					"Answer: %s + C" % ans2,
				],
			}
		2:
			var a3 := rng.randi_range(2, 7)
			var n3 := rng.randi_range(1, 3)
			var p3 := rng.randi_range(1, 3)
			var b3 := p3 * (n3 + 1)
			var ans3 := join_terms([coef(a3, 1, "ln|x|"), coef(p3, 1, xpow(n3 + 1))])
			return {
				"lead": "Integrate with respect to x.",
				"integral": integral("(%d/x + %s) dx" % [a3, coef(b3, 1, xpow(n3))]),
				"integrand": "%d/x + %d*x^%d" % [a3, b3, n3],
				"answer": "%d*ln(x) + %d*x^%d" % [a3, p3, n3 + 1],
				"answer_display": ans3 + " + C",
				"hints": [
					"The power rule fails for x⁻¹ — it has its own rule.",
					"∫(1/x) dx = ln|x| + C.",
					"So ∫(%d/x) dx = %dln|x|. Now integrate %s with the power rule." % [a3, a3, coef(b3, 1, xpow(n3))],
				],
				"steps": [
					"Split the integral into two parts.",
					"∫%d/x dx = %dln|x| (special case n = −1)." % [a3, a3],
					"∫%s dx = %s" % [coef(b3, 1, xpow(n3)), coef(p3, 1, xpow(n3 + 1))],
					"Answer: %s + C" % ans3,
				],
			}
		_:
			var k4 := rng.randi_range(2, 4)
			var p4 := rng.randi_range(1, 3)
			var a4 := k4 * p4
			var ans4 := coef(-p4, 1, "cos(%dx)" % k4)
			return {
				"lead": "Integrate with respect to x.",
				"integral": integral("%s dx" % coef(a4, 1, "sin(%dx)" % k4)),
				"integrand": "%d*sin(%d*x)" % [a4, k4],
				"answer": "-%d*cos(%d*x)" % [p4, k4],
				"answer_display": ans4 + " + C",
				"hints": [
					"∫sin(kx) dx = −cos(kx)/k + C. Watch the minus sign!",
					"Take the %d outside first." % a4,
					"%d ÷ %d = %d, and the sign becomes negative." % [a4, k4, p4],
				],
				"steps": [
					"Recall d/dx[cos(kx)] = −k·sin(kx), so ∫sin(kx) dx = −cos(kx)/k.",
					"%d · (−cos(%dx)/%d) = %s" % [a4, k4, k4, ans4],
					"Answer: %s + C" % ans4,
				],
			}


static func _substitution(rng: RandomNumberGenerator) -> Dictionary:
	var variant := rng.randi_range(0, 3)
	match variant:
		0:
			var b := rng.randi_range(2, 4)
			var c := rng.randi_range(1, 5)
			var n := rng.randi_range(2, 4)
			var p := rng.randi_range(1, 2)
			var a := b * (n + 1) * p
			var inner := "%dx + %d" % [b, c]
			var ans := coef(p, 1, "(%s)%s" % [inner, sup(n + 1)])
			return {
				"lead": "Integrate using a substitution.",
				"integral": integral("%d(%s)%s dx" % [a, inner, sup(n)]),
				"integrand": "%d*(%d*x+%d)^%d" % [a, b, c, n],
				"answer": "%d*(%d*x+%d)^%d" % [p, b, c, n + 1],
				"answer_display": ans + " + C",
				"hints": [
					"Let u = %s (the inner function)." % inner,
					"Then du/dx = %d, so dx = du/%d." % [b, b],
					"The integral becomes ∫%d·u%s·(du/%d) = ∫%du%s du." % [a, sup(n), b, a / b, sup(n)],
				],
				"steps": [
					"Let u = %s, so du = %d dx and dx = du/%d." % [inner, b, b],
					"∫%d(%s)%s dx = ∫%du%s du" % [a, inner, sup(n), a / b, sup(n)],
					"= %du%s/%d = %s" % [a / b, sup(n + 1), n + 1, coef(p, 1, "u" + sup(n + 1))],
					"Substitute back u = %s:  %s + C" % [inner, ans],
				],
			}
		1:
			var n2 := rng.randi_range(1, 3)
			var c2 := rng.randi_range(1, 5)
			var p2 := rng.randi_range(1, 2)
			var a2 := 2 * (n2 + 1) * p2
			var inner2 := "x² + %d" % c2
			var ans2 := coef(p2, 1, "(%s)%s" % [inner2, sup(n2 + 1)])
			return {
				"lead": "Integrate using a substitution.",
				"integral": integral("%dx(%s)%s dx" % [a2, inner2, sup(n2) if n2 > 1 else ""]),
				"integrand": "%d*x*(x^2+%d)^%d" % [a2, c2, n2],
				"answer": "%d*(x^2+%d)^%d" % [p2, c2, n2 + 1],
				"answer_display": ans2 + " + C",
				"hints": [
					"Look for a function and its derivative: the derivative of x² + %d is 2x." % c2,
					"Let u = %s, so du = 2x dx." % inner2,
					"%dx dx = %d du, so the integral is ∫%du%s du." % [a2, a2 / 2, a2 / 2, sup(n2) if n2 > 1 else ""],
				],
				"steps": [
					"Let u = %s, so du = 2x dx  ⇒  x dx = du/2." % inner2,
					"∫%dx(%s)%s dx = ∫%du%s du" % [a2, inner2, sup(n2) if n2 > 1 else "", a2 / 2, sup(n2) if n2 > 1 else ""],
					"= %du%s/%d = %s" % [a2 / 2, sup(n2 + 1), n2 + 1, coef(p2, 1, "u" + sup(n2 + 1))],
					"Substitute back:  %s + C" % ans2,
				],
			}
		2:
			var p3 := rng.randi_range(1, 3)
			var a3 := 2 * p3
			var ans3 := coef(p3, 1, "e^(x²)")
			return {
				"lead": "Integrate using a substitution.",
				"integral": integral("%dx·e^(x²) dx" % a3),
				"integrand": "%d*x*e^(x^2)" % a3,
				"answer": "%d*e^(x^2)" % p3,
				"answer_display": ans3 + " + C",
				"hints": [
					"The exponent x² has derivative 2x — and there's an x outside!",
					"Let u = x², so du = 2x dx.",
					"%dx dx = %d du, and ∫eᵘ du = eᵘ." % [a3, p3],
				],
				"steps": [
					"Let u = x², so du = 2x dx.",
					"∫%dx·e^(x²) dx = ∫%deᵘ du" % [a3, p3],
					"= %s" % coef(p3, 1, "eᵘ"),
					"Substitute back:  %s + C" % ans3,
				],
			}
		_:
			var b4 := rng.randi_range(1, 5)
			var c4 := rng.randi_range(1, 6)
			var p4 := rng.randi_range(1, 3)
			var denom := join_terms(["x²", coef(b4, 1, "x"), coef(c4, 1, "")])
			var numer := join_terms([coef(2 * p4, 1, "x"), coef(b4 * p4, 1, "")])
			var ans4 := coef(p4, 1, "ln|%s|" % denom)
			return {
				"lead": "Integrate using a substitution.",
				"integral": integral("(%s)/(%s) dx" % [numer, denom]),
				"integrand": "(%d*x+%d)/(x^2+%d*x+%d)" % [2 * p4, b4 * p4, b4, c4],
				"answer": "%d*ln(x^2+%d*x+%d)" % [p4, b4, c4],
				"answer_display": ans4 + " + C",
				"hints": [
					"Differentiate the denominator. What do you notice about the numerator?",
					"Let u = %s, so du = (2x + %d) dx." % [denom, b4],
					"The integral becomes ∫%d/u du = %dln|u|." % [p4, p4] if p4 > 1 else "The integral becomes ∫1/u du = ln|u|.",
				],
				"steps": [
					"The numerator is %d × the derivative of the denominator." % p4 if p4 > 1 else "The numerator is exactly the derivative of the denominator.",
					"Let u = %s, du = (2x + %d) dx." % [denom, b4],
					"∫(%s)/(%s) dx = ∫%s du" % [numer, denom, coef(p4, 1, "1/u") if p4 > 1 else "1/u"],
					"= %s + C" % ans4,
				],
			}


static func _parts(rng: RandomNumberGenerator) -> Dictionary:
	var variant := rng.randi_range(0, 4)
	var k := rng.randi_range(1, 3)
	var kx := "x" if k == 1 else "%dx" % k
	match variant:
		0:
			var e_term := "e^(%s)" % kx if k > 1 else "eˣ"
			var v := coef(1, k, e_term)
			var ans := join_terms([coef(1, k, "x" + ("·" + e_term)), coef(-1, k * k, e_term)])
			return {
				"lead": "Integrate by parts.",
				"integral": integral("x·%s dx" % e_term),
				"integrand": "x*e^(%d*x)" % k,
				"answer": "x*e^(%d*x)/%d - e^(%d*x)/%d" % [k, k, k, k * k],
				"answer_display": ans + " + C",
				"hints": [
					"LIATE: choose u = x (algebraic) and dv = %s dx." % e_term,
					"Then du = dx and v = %s." % v,
					"Use ∫u dv = uv − ∫v du:  x·%s − ∫%s dx." % [v, v],
				],
				"steps": [
					"Let u = x and dv = %s dx." % e_term,
					"du = dx and v = %s." % v,
					"∫x·%s dx = x·%s − ∫%s dx" % [e_term, v, v],
					"= %s + C" % ans,
				],
			}
		1:
			var cos_t := "cos(%s)" % kx if k > 1 else "cos x"
			var sin_t := "sin(%s)" % kx if k > 1 else "sin x"
			var ans1 := join_terms([coef(1, k, "x·" + sin_t), coef(1, k * k, cos_t)])
			return {
				"lead": "Integrate by parts.",
				"integral": integral("x·%s dx" % cos_t),
				"integrand": "x*cos(%d*x)" % k,
				"answer": "x*sin(%d*x)/%d + cos(%d*x)/%d" % [k, k, k, k * k],
				"answer_display": ans1 + " + C",
				"hints": [
					"LIATE: u = x, dv = %s dx." % cos_t,
					"du = dx and v = %s." % coef(1, k, sin_t),
					"∫%s dx = %s, and the minus signs combine to a plus." % [coef(1, k, sin_t), coef(-1, k * k, cos_t)],
				],
				"steps": [
					"Let u = x and dv = %s dx." % cos_t,
					"du = dx and v = %s." % coef(1, k, sin_t),
					"∫x·%s dx = %s − ∫%s dx" % [cos_t, coef(1, k, "x·" + sin_t), coef(1, k, sin_t)],
					"= %s + C" % ans1,
				],
			}
		2:
			var sin2 := "sin(%s)" % kx if k > 1 else "sin x"
			var cos2 := "cos(%s)" % kx if k > 1 else "cos x"
			var ans2 := join_terms([coef(-1, k, "x·" + cos2), coef(1, k * k, sin2)])
			return {
				"lead": "Integrate by parts.",
				"integral": integral("x·%s dx" % sin2),
				"integrand": "x*sin(%d*x)" % k,
				"answer": "-x*cos(%d*x)/%d + sin(%d*x)/%d" % [k, k, k, k * k],
				"answer_display": ans2 + " + C",
				"hints": [
					"LIATE: u = x, dv = %s dx." % sin2,
					"du = dx and v = %s." % coef(-1, k, cos2),
					"uv − ∫v du = %s + ∫%s dx." % [coef(-1, k, "x·" + cos2), coef(1, k, cos2)],
				],
				"steps": [
					"Let u = x and dv = %s dx." % sin2,
					"du = dx and v = %s." % coef(-1, k, cos2),
					"∫x·%s dx = %s + ∫%s dx" % [sin2, coef(-1, k, "x·" + cos2), coef(1, k, cos2)],
					"= %s + C" % ans2,
				],
			}
		3:
			return {
				"lead": "Integrate by parts.",
				"integral": integral("ln x dx"),
				"integrand": "ln(x)",
				"answer": "x*ln(x) - x",
				"answer_display": "x·ln x − x + C",
				"hints": [
					"Write ln x as 1·ln x. LIATE says u = ln x (logarithmic).",
					"u = ln x, dv = dx  ⇒  du = (1/x) dx, v = x.",
					"x·ln x − ∫x·(1/x) dx = x·ln x − ∫1 dx.",
				],
				"steps": [
					"Let u = ln x and dv = 1 dx.",
					"du = (1/x) dx and v = x.",
					"∫ln x dx = x·ln x − ∫x·(1/x) dx = x·ln x − ∫1 dx",
					"= x·ln x − x + C",
				],
			}
		_:
			return {
				"lead": "Integrate by parts.",
				"integral": integral("x·ln x dx"),
				"integrand": "x*ln(x)",
				"answer": "x^2*ln(x)/2 - x^2/4",
				"answer_display": "x²·ln x/2 − x²/4 + C",
				"hints": [
					"LIATE puts logarithms first: u = ln x, dv = x dx.",
					"du = (1/x) dx and v = x²/2.",
					"uv − ∫v du = (x²/2)ln x − ∫(x/2) dx.",
				],
				"steps": [
					"Let u = ln x and dv = x dx.",
					"du = (1/x) dx and v = x²/2.",
					"∫x·ln x dx = (x²/2)·ln x − ∫(x²/2)(1/x) dx = (x²/2)·ln x − ∫(x/2) dx",
					"= x²·ln x/2 − x²/4 + C",
				],
			}


static func _partial_fractions(rng: RandomNumberGenerator) -> Dictionary:
	var a := rng.randi_range(1, 5)
	var b := rng.randi_range(1, 5)
	while b == a:
		b = rng.randi_range(1, 5)
	var A := nonzero(rng, -3, 4)
	var B := nonzero(rng, -3, 4)
	var p := A + B
	var q := A * b + B * a
	var numer := signed_linear(p, q)
	var fa := "x + %d" % a
	var fb := "x + %d" % b
	var ans := join_terms([coef(A, 1, "ln|%s|" % fa), coef(B, 1, "ln|%s|" % fb)])
	var numer_text := numer if (p == 0 or q == 0) else "(%s)" % numer
	return {
		"lead": "Integrate using partial fractions.",
		"integral": integral("%s / ((%s)(%s)) dx" % [numer_text, fa, fb]),
		"integrand": "(%d*x+%d)/((x+%d)*(x+%d))" % [p, q, a, b],
		"answer": "%d*ln(x+%d) + %d*ln(x+%d)" % [A, a, B, b],
		"answer_display": ans + " + C",
		"hints": [
			"Write it as A/(%s) + B/(%s)." % [fa, fb],
			"Multiply out: %s = A(%s) + B(%s). Try x = −%d and x = −%d." % [numer, fb, fa, a, b],
			"You should find A = %d and B = %d. Each piece integrates to a logarithm." % [A, B],
		],
		"steps": [
			"%s / ((%s)(%s)) = A/(%s) + B/(%s)" % [numer_text, fa, fb, fa, fb],
			"So %s = A(%s) + B(%s)." % [numer, fb, fa],
			"x = −%d:  %d = A(%d)  ⇒  A = %d.   x = −%d:  %d = B(%d)  ⇒  B = %d." % [a, p * -a + q, b - a, A, b, p * -b + q, a - b, B],
			"∫[%s] dx = %s + C" % [join_terms([coef(A, 1, "") + "/(%s)" % fa, coef(B, 1, "") + "/(%s)" % fb]), ans],
		],
	}


static func _definite(rng: RandomNumberGenerator) -> Dictionary:
	var variant := rng.randi_range(0, 4)
	if variant <= 1:
		var n := rng.randi_range(1, 3)
		var p := rng.randi_range(1, 3)
		var lo := rng.randi_range(0, 2)
		var hi := rng.randi_range(lo + 1, 3)
		var k := p * (n + 1)
		var value := p * (int(pow(hi, n + 1)) - int(pow(lo, n + 1)))
		var big_f := coef(p, 1, xpow(n + 1))
		return {
			"kind": "definite",
			"lead": "Evaluate the definite integral.",
			"integral": integral("%s dx" % coef(k, 1, xpow(n)), str(lo), str(hi)),
			"integrand": "%d*x^%d" % [k, n],
			"antiderivative": "%d*x^%d" % [p, n + 1],
			"lower": float(lo), "upper": float(hi),
			"value": float(value),
			"answer_display": str(value),
			"hints": [
				"First find an antiderivative F(x) of %s." % coef(k, 1, xpow(n)),
				"F(x) = %s. No + C is needed for definite integrals." % big_f,
				"Compute F(%d) − F(%d)." % [hi, lo],
			],
			"steps": [
				"Antiderivative: F(x) = %s." % big_f,
				"F(%d) = %d,  F(%d) = %d." % [hi, p * int(pow(hi, n + 1)), lo, p * int(pow(lo, n + 1))],
				"F(%d) − F(%d) = %d − %d = %d" % [hi, lo, p * int(pow(hi, n + 1)), p * int(pow(lo, n + 1)), value],
			],
		}
	if variant == 2:
		var lo2 := rng.randi_range(0, 2)
		var hi2 := rng.randi_range(lo2 + 1, 4)
		var m := rng.randi_range(1, 3) * 2
		var c := rng.randi_range(1, 5)
		var fhi := m / 2 * hi2 * hi2 + c * hi2
		var flo := m / 2 * lo2 * lo2 + c * lo2
		var big_f2 := join_terms([coef(m / 2, 1, "x²"), coef(c, 1, "x")])
		return {
			"kind": "definite",
			"lead": "Evaluate the definite integral.",
			"integral": integral("(%s) dx" % join_terms([coef(m, 1, "x"), coef(c, 1, "")]), str(lo2), str(hi2)),
			"integrand": "%d*x + %d" % [m, c],
			"antiderivative": "%d*x^2 + %d*x" % [m / 2, c],
			"lower": float(lo2), "upper": float(hi2),
			"value": float(fhi - flo),
			"answer_display": str(fhi - flo),
			"hints": [
				"Integrate each term: ∫%s dx and ∫%d dx." % [coef(m, 1, "x"), c],
				"F(x) = %s." % big_f2,
				"Compute F(%d) − F(%d)." % [hi2, lo2],
			],
			"steps": [
				"F(x) = %s." % big_f2,
				"F(%d) = %d,  F(%d) = %d." % [hi2, fhi, lo2, flo],
				"Answer: %d − %d = %d" % [fhi, flo, fhi - flo],
			],
		}
	var k3 := rng.randi_range(2, 5)
	if variant == 3:
		return {
			"kind": "definite",
			"lead": "Evaluate the definite integral.",
			"integral": integral("%dcos x dx" % k3, "0", "π/2"),
			"integrand": "%d*cos(x)" % k3,
			"antiderivative": "%d*sin(x)" % k3,
			"lower": 0.0, "upper": PI / 2.0,
			"value": float(k3),
			"answer_display": str(k3),
			"hints": [
				"∫cos x dx = sin x.",
				"F(x) = %dsin x." % k3,
				"sin(π/2) = 1 and sin 0 = 0.",
			],
			"steps": [
				"F(x) = %dsin x." % k3,
				"F(π/2) − F(0) = %d·1 − %d·0" % [k3, k3],
				"= %d" % k3,
			],
		}
	return {
		"kind": "definite",
		"lead": "Evaluate the definite integral.",
		"integral": integral("%dsin x dx" % k3, "0", "π"),
		"integrand": "%d*sin(x)" % k3,
		"antiderivative": "-%d*cos(x)" % k3,
		"lower": 0.0, "upper": PI,
		"value": float(2 * k3),
		"answer_display": str(2 * k3),
		"hints": [
			"∫sin x dx = −cos x.",
			"F(x) = −%dcos x." % k3,
			"cos π = −1 and cos 0 = 1. Be careful with the double negative.",
		],
		"steps": [
			"F(x) = −%dcos x." % k3,
			"F(π) = −%d·(−1) = %d,  F(0) = −%d·1 = −%d." % [k3, k3, k3, k3],
			"F(π) − F(0) = %d − (−%d) = %d" % [k3, k3, 2 * k3],
		],
	}


# ---------------------------------------------------------------- checking

## Returns {"status": "correct"|"missing_c"|"wrong"|"invalid", "message": String}
static func check(problem: Dictionary, answer_text: String) -> Dictionary:
	var parsed := MathExpr.parse(answer_text)
	if not parsed.ok:
		return {"status": "invalid", "message": str(parsed.error) + "  Tip: write powers as x^3 and use brackets, e.g. e^(2x)."}
	if str(problem.get("kind", "indefinite")) == "definite":
		return _check_definite(problem, parsed)
	return _check_indefinite(problem, parsed)


static func _check_definite(problem: Dictionary, parsed: Dictionary) -> Dictionary:
	if parsed.uses_x:
		return {"status": "wrong", "message": "A definite integral gives a number, not a function of x. Substitute the limits into F(x) and subtract."}
	if parsed.uses_c:
		return {"status": "wrong", "message": "No + C needed here — the constants cancel when you compute F(b) − F(a)."}
	var value := MathExpr.evaluate(parsed.ast, 0.0)
	var target := float(problem.value)
	if is_nan(value):
		return {"status": "invalid", "message": "I couldn't work out a value from that. Try a plain number such as 12 or 7/2."}
	if _close(value, target):
		return {"status": "correct", "message": "Exactly right!"}
	if _close(value, -target):
		return {"status": "wrong", "message": "So close — the sign is flipped. Remember it's F(upper) − F(lower)."}
	var antiderivative := MathExpr.parse(str(problem.get("antiderivative", "")))
	if antiderivative.ok:
		var f_hi := MathExpr.evaluate(antiderivative.ast, float(problem.upper))
		var f_lo := MathExpr.evaluate(antiderivative.ast, float(problem.lower))
		if _close(value, f_hi) and not _close(f_lo, 0.0):
			return {"status": "wrong", "message": "That's F(upper) only. Don't forget to subtract F(lower)."}
		if _close(value, f_hi + f_lo):
			return {"status": "wrong", "message": "You added F(lower). It should be subtracted: F(upper) − F(lower)."}
	var integrand := MathExpr.parse(str(problem.integrand))
	if integrand.ok:
		var g_diff := MathExpr.evaluate(integrand.ast, float(problem.upper)) - MathExpr.evaluate(integrand.ast, float(problem.lower))
		if _close(value, g_diff):
			return {"status": "wrong", "message": "You substituted into the integrand itself. Integrate first to find F(x), then substitute."}
	return {"status": "wrong", "message": "Not quite. Find F(x) first, then carefully evaluate F(upper) − F(lower)."}


static func _check_indefinite(problem: Dictionary, parsed: Dictionary) -> Dictionary:
	var reference := MathExpr.parse(str(problem.answer))
	var integrand := MathExpr.parse(str(problem.integrand))
	if not reference.ok or not integrand.ok:
		return {"status": "invalid", "message": "This challenge could not be checked. Try the next one."}
	if not parsed.uses_x:
		return {"status": "wrong", "message": "Your answer should be a function of x."}
	var differences: Array[float] = []
	var scale := 1.0
	for sample: float in SAMPLE_XS:
		var s := MathExpr.evaluate(parsed.ast, sample, 0.0)
		var r := MathExpr.evaluate(reference.ast, sample, 0.0)
		if is_nan(s) or is_inf(s):
			return {"status": "wrong", "message": "Your expression is undefined for some x > 0. Check logs, roots and brackets."}
		differences.append(s - r)
		scale = maxf(scale, absf(r))
	var constant_offset := true
	for d: float in differences:
		if absf(d - differences[0]) > 1e-6 * scale + 1e-7:
			constant_offset = false
			break
	if constant_offset:
		if not parsed.uses_c:
			return {"status": "missing_c", "message": "Your antiderivative is right — but an indefinite integral needs “+ C”. Add it and check again."}
		var additive := true
		for sample: float in SAMPLE_XS:
			var shift := MathExpr.evaluate(parsed.ast, sample, 1.0) - MathExpr.evaluate(parsed.ast, sample, 0.0)
			if absf(shift - 1.0) > 1e-6:
				additive = false
				break
		if not additive:
			return {"status": "missing_c", "message": "Nearly there — write the constant as a separate “+ C” term at the end."}
		return {"status": "correct", "message": "Correct! Differentiating your answer gives back the integrand."}
	return {"status": "wrong", "message": _diagnose(parsed.ast, integrand.ast)}


static func _diagnose(student_ast: Variant, integrand_ast: Variant) -> String:
	var h := 1e-4
	var ratios: Array[float] = []
	var equals_integrand := true
	var equals_derivative := true
	for sample: float in SAMPLE_XS:
		var f := MathExpr.evaluate(integrand_ast, sample)
		var s := MathExpr.evaluate(student_ast, sample)
		var ds := (MathExpr.evaluate(student_ast, sample + h) - MathExpr.evaluate(student_ast, sample - h)) / (2.0 * h)
		var df := (MathExpr.evaluate(integrand_ast, sample + h) - MathExpr.evaluate(integrand_ast, sample - h)) / (2.0 * h)
		if absf(f) > 1e-6:
			ratios.append(ds / f)
		if not _close(s, f):
			equals_integrand = false
		if not _close(s, df):
			equals_derivative = false
	if equals_integrand:
		return "That's the integrand itself. Find a function whose derivative is this expression."
	if equals_derivative:
		return "That looks like the derivative. Integration goes the other way — reverse the differentiation."
	if ratios.size() >= 3:
		var consistent := true
		for r: float in ratios:
			if absf(r - ratios[0]) > 1e-3 * maxf(1.0, absf(ratios[0])):
				consistent = false
				break
		if consistent:
			var factor := ratios[0]
			if _close(factor, -1.0):
				return "Right shape, wrong sign. Check minus signs — e.g. ∫sin x dx = −cos x."
			if absf(factor) > 1e-6:
				return "Right shape, but the coefficient is off: your answer differentiates to %s× the integrand. Check the number you divide by." % _pretty_number(factor)
	return "Not quite. Differentiate your answer — it should give back the integrand. Try a hint if you're stuck."


static func _pretty_number(value: float) -> String:
	for den: int in [1, 2, 3, 4, 5, 6, 8, 9]:
		var num := value * den
		if absf(num - roundf(num)) < 1e-3:
			var n := int(roundf(num))
			return str(n) if den == 1 else "%d/%d" % [n, den]
	return "%.2f" % value


static func _close(a: float, b: float) -> bool:
	return absf(a - b) <= 0.01 + 0.002 * absf(b)


## Reward after a correct answer given the number of hints used and whether the solution was shown.
static func reward(problem: Dictionary, hints_used: int, solution_shown: bool, streak: int) -> Dictionary:
	if solution_shown:
		return {"coins": 0, "xp": 4}
	var coins := float(problem.coins) * maxf(0.4, 1.0 - 0.25 * hints_used)
	coins += mini(streak, 5)
	return {"coins": int(roundf(coins)), "xp": int(problem.xp) - 2 * hints_used}


# ---------------------------------------------------------------- mini-game content

## Antiderivative Catch: returns {"target": String, "correct": String, "wrong": Array[String]}
static func catch_round(rng: RandomNumberGenerator) -> Dictionary:
	var variant := rng.randi_range(0, 5)
	match variant:
		0, 1:
			var n := rng.randi_range(1, 4)
			var p := rng.randi_range(1, 3)
			var c := p * (n + 1)
			return {
				"target": "∫ %s dx" % coef(c, 1, xpow(n)),
				"correct": coef(p, 1, xpow(n + 1)),
				"wrong": _distinct([coef(c, 1, xpow(n + 1)), coef(c * n, 1, xpow(n - 1)), coef(p, 1, xpow(n)), coef(c, n + 2, xpow(n + 2))], coef(p, 1, xpow(n + 1))),
			}
		2:
			var k := rng.randi_range(2, 4)
			return {
				"target": "∫ cos(%dx) dx" % k,
				"correct": coef(1, k, "sin(%dx)" % k),
				"wrong": _distinct([coef(-1, k, "sin(%dx)" % k), coef(k, 1, "sin(%dx)" % k), coef(1, k, "cos(%dx)" % k)], ""),
			}
		3:
			var k2 := rng.randi_range(2, 4)
			return {
				"target": "∫ sin(%dx) dx" % k2,
				"correct": coef(-1, k2, "cos(%dx)" % k2),
				"wrong": _distinct([coef(1, k2, "cos(%dx)" % k2), coef(-k2, 1, "cos(%dx)" % k2), coef(-1, 1, "sin(%dx)" % k2)], ""),
			}
		4:
			var k3 := rng.randi_range(2, 5)
			return {
				"target": "∫ e^(%dx) dx" % k3,
				"correct": coef(1, k3, "e^(%dx)" % k3),
				"wrong": _distinct([coef(k3, 1, "e^(%dx)" % k3), "e^(%dx)" % k3, coef(1, k3 + 1, "e^(%dx)" % (k3 + 1))], ""),
			}
		_:
			var a := rng.randi_range(1, 4)
			return {
				"target": "∫ %s dx" % ("1/x" if a == 1 else "%d/x" % a),
				"correct": coef(a, 1, "ln|x|"),
				"wrong": _distinct(["−%d/x²" % a, coef(a * 2, 1, "ln|x|"), "%d/x²" % a, coef(a, 2, "x²")], ""),
			}


static func _distinct(values: Array, exclude: String) -> Array:
	var out: Array = []
	for value: Variant in values:
		var text := str(value)
		if text != exclude and text != "0" and not out.has(text):
			out.append(text)
	return out


## Area Pour: returns {"label": Dictionary(integral spec), "expr": String, "a": float, "b": float, "value": float}
static func pour_round(rng: RandomNumberGenerator, round_index: int) -> Dictionary:
	var options := [
		func() -> Dictionary:
			var lo := rng.randi_range(0, 1)
			var hi := rng.randi_range(lo + 2, 4)
			return {"label": integral("2x dx", str(lo), str(hi)), "expr": "2*x", "a": float(lo), "b": float(hi), "value": float(hi * hi - lo * lo)},
		func() -> Dictionary:
			var hi := rng.randi_range(1, 2)
			return {"label": integral("3x² dx", "0", str(hi)), "expr": "3*x^2", "a": 0.0, "b": float(hi), "value": float(hi * hi * hi)},
		func() -> Dictionary:
			var hi := rng.randi_range(2, 4)
			var c := rng.randi_range(1, 3)
			return {"label": integral("(x + %d) dx" % c, "0", str(hi)), "expr": "x + %d" % c, "a": 0.0, "b": float(hi), "value": hi * hi / 2.0 + c * hi},
		func() -> Dictionary:
			return {"label": integral("(6 − 2x) dx", "0", "2"), "expr": "6 - 2*x", "a": 0.0, "b": 2.0, "value": 8.0},
		func() -> Dictionary:
			var k := rng.randi_range(2, 4)
			return {"label": integral("%dcos x dx" % k, "0", "π/2"), "expr": "%d*cos(x)" % k, "a": 0.0, "b": PI / 2.0, "value": float(k)},
		func() -> Dictionary:
			var k := rng.randi_range(1, 3)
			return {"label": integral("%dsin x dx" % k if k > 1 else "sin x dx", "0", "π"), "expr": "%d*sin(x)" % k, "a": 0.0, "b": PI, "value": 2.0 * k},
		func() -> Dictionary:
			var k := rng.randi_range(2, 6)
			return {"label": integral("%d/x dx" % k, "1", "e"), "expr": "%d/x" % k, "a": 1.0, "b": exp(1.0), "value": float(k)},
		func() -> Dictionary:
			return {"label": integral("4x³ dx", "1", "2"), "expr": "4*x^3", "a": 1.0, "b": 2.0, "value": 15.0},
	]
	var index := (round_index * 3 + rng.randi_range(0, options.size() - 1)) % options.size()
	return (options[index] as Callable).call()
