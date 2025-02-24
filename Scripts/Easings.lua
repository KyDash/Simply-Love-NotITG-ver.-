_SL.Easing = {}

local sqrt = math.sqrt
local sin = math.sin
local asin = math.asin
local cos = math.cos
local pow = math.pow
local exp = math.exp
local pi = math.pi
local abs = math.abs

-- Utility functions


_SL.Easing.flip = setmetatable({}, {
	__call = function(self, fn)
		self[fn] = self[fn] or function(x)
			return 1 - fn(x)
		end
		return self[fn]
	end,
})

-- Mix two easing functions together into a new ease
-- the new ease starts by acting like the first argument, and then ends like the second argument
-- Example: blendease(inQuad, outQuad)
_SL.Easing.blendease = setmetatable({}, {
	__index = function(self, key)
		self[key] = {}
		return self[key]
	end,
	__call = function(self, fn1, fn2)
		if not self[fn1][fn2] then
			local transient1 = fn1(1) <= 0.5
			local transient2 = fn2(1) <= 0.5
			if transient1 and not transient2 then
				error("blendease: the first argument is a transient ease, but the second argument doesn't match")
			end
			if transient2 and not transient1 then
				error("blendease: the second argument is a transient ease, but the first argument doesn't match")
			end
			self[fn1][fn2] = function(x)
				local mixFactor = 3 * x ^ 2 - 2 * x ^ 3
				return (1 - mixFactor) * fn1(x) + mixFactor * fn2(x)
			end
		end
		return self[fn1][fn2]
	end,
})

local function param1cache(self, param1)
	self.cache[param1] = self.cache[param1] or function(x)
		return self.fn(x, param1)
	end
	return self.cache[param1]
end

local param1mt = {
	__call = function(self, x, param1)
		return self.fn(x, param1 or self.dp1)
	end,
	__index = {
		param = param1cache,
		params = param1cache,
	},
}

-- Declare an easing function taking one custom parameter
local function with1param(fn, defaultparam1)
	return setmetatable({
		fn = fn,
		dp1 = defaultparam1,
		cache = {},
	}, param1mt)
end

local function param2cache(self, param1, param2)
	self.cache[param1] = self.cache[param1] or {}
	self.cache[param1][param2] = self.cache[param1][param2] or function(x)
		return self.fn(x, param1, param2)
	end
	return self.cache[param1][param2]
end

local param2mt = {
	__call = function(self, x, param1, param2)
		return self.fn(x, param1 or self.dp1, param2 or self.dp2)
	end,
	__index = {
		param = param2cache,
		params = param2cache,
	},
}

-- Declare an easing function taking two custom parameters
local function with2params(fn, defaultparam1, defaultparam2)
	return setmetatable({
		fn = fn,
		dp1 = defaultparam1,
		dp2 = defaultparam2,
		cache = {},
	}, param2mt)
end

-- ===================================================================== --

-- Easing functions

_SL.Easing.bounce = function(t)
	return 4 * t * (1 - t)
end
_SL.Easing.tri = function(t)
	return 1 - abs(2 * t - 1)
end
_SL.Easing.bell = function(t)
	return inOutQuint(tri(t))
end
_SL.Easing.pop = function(t)
	return 3.5 * (1 - t) * (1 - t) * sqrt(t)
end
_SL.Easing.tap = function(t)
	return 3.5 * t * t * sqrt(1 - t)
end
_SL.Easing.pulse = function(t)
	return t < 0.5 and tap(t * 2) or -pop(t * 2 - 1)
end

_SL.Easing.spike = function(t)
	return exp(-10 * abs(2 * t - 1))
end
_SL.Easing.inverse = function(t)
	return t * t * (1 - t) * (1 - t) / (0.5 - t)
end

local function popElasticInternal(t, damp, count)
	return (1000 ^ -(t ^ damp) - 0.001) * sin(count * pi * t)
end

local function tapElasticInternal(t, damp, count)
	return (1000 ^ -((1 - t) ^ damp) - 0.001) * sin(count * pi * (1 - t))
end

local function pulseElasticInternal(t, damp, count)
	if t < 0.5 then
		return tapElasticInternal(t * 2, damp, count)
	else
		return -popElasticInternal(t * 2 - 1, damp, count)
	end
end

_SL.Easing.popElastic = with2params(popElasticInternal, 1.4, 6)
_SL.Easing.tapElastic = with2params(tapElasticInternal, 1.4, 6)
_SL.Easing.pulseElastic = with2params(pulseElasticInternal, 1.4, 6)

_SL.Easing.impulse = with1param(function(t, damp)
	t = t ^ damp
	return t * (1000 ^ -t - 0.001) * 18.6
end, 0.9)

_SL.Easing.instant = function()
	return 1
end
_SL.Easing.linear = function(t)
	return t
end
_SL.Easing.inQuad = function(t)
	return t * t
end
_SL.Easing.outQuad = function(t)
	return -t * (t - 2)
end
_SL.Easing.inOutQuad = function(t)
	t = t * 2
	if t < 1 then
		return 0.5 * t ^ 2
	else
		return 1 - 0.5 * (2 - t) ^ 2
	end
end
_SL.Easing.outInQuad = function(t)
	t = t * 2
	if t < 1 then
		return 0.5 - 0.5 * (1 - t) ^ 2
	else
		return 0.5 + 0.5 * (t - 1) ^ 2
	end
end
_SL.Easing.inCubic = function(t)
	return t * t * t
end
_SL.Easing.outCubic = function(t)
	return 1 - (1 - t) ^ 3
end
_SL.Easing.inOutCubic = function(t)
	t = t * 2
	if t < 1 then
		return 0.5 * t ^ 3
	else
		return 1 - 0.5 * (2 - t) ^ 3
	end
end
_SL.Easing.outInCubic = function(t)
	t = t * 2
	if t < 1 then
		return 0.5 - 0.5 * (1 - t) ^ 3
	else
		return 0.5 + 0.5 * (t - 1) ^ 3
	end
end
_SL.Easing.inQuart = function(t)
	return t * t * t * t
end
_SL.Easing.outQuart = function(t)
	return 1 - (1 - t) ^ 4
end
_SL.Easing.inOutQuart = function(t)
	t = t * 2
	if t < 1 then
		return 0.5 * t ^ 4
	else
		return 1 - 0.5 * (2 - t) ^ 4
	end
end
_SL.Easing.outInQuart = function(t)
	t = t * 2
	if t < 1 then
		return 0.5 - 0.5 * (1 - t) ^ 4
	else
		return 0.5 + 0.5 * (t - 1) ^ 4
	end
end
_SL.Easing.inQuint = function(t)
	return t ^ 5
end
_SL.Easing.outQuint = function(t)
	return 1 - (1 - t) ^ 5
end
_SL.Easing.inOutQuint = function(t)
	t = t * 2
	if t < 1 then
		return 0.5 * t ^ 5
	else
		return 1 - 0.5 * (2 - t) ^ 5
	end
end
_SL.Easing.outInQuint = function(t)
	t = t * 2
	if t < 1 then
		return 0.5 - 0.5 * (1 - t) ^ 5
	else
		return 0.5 + 0.5 * (t - 1) ^ 5
	end
end
_SL.Easing.inExpo = function(t)
	return 1000 ^ (t - 1) - 0.001
end
_SL.Easing.outExpo = function(t)
	return 1.001 - 1000 ^ -t
end
_SL.Easing.inOutExpo = function(t)
	t = t * 2
	if t < 1 then
		return 0.5 * 1000 ^ (t - 1) - 0.0005
	else
		return 1.0005 - 0.5 * 1000 ^ (1 - t)
	end
end
_SL.Easing.outInExpo = function(t)
	if t < 0.5 then
		return outExpo(t * 2) * 0.5
	else
		return inExpo(t * 2 - 1) * 0.5 + 0.5
	end
end
_SL.Easing.inCirc = function(t)
	return 1 - sqrt(1 - t * t)
end
_SL.Easing.outCirc = function(t)
	return sqrt(-t * t + 2 * t)
end
_SL.Easing.inOutCirc = function(t)
	t = t * 2
	if t < 1 then
		return 0.5 - 0.5 * sqrt(1 - t * t)
	else
		t = t - 2
		return 0.5 + 0.5 * sqrt(1 - t * t)
	end
end
_SL.Easing.outInCirc = function(t)
	if t < 0.5 then
		return outCirc(t * 2) * 0.5
	else
		return inCirc(t * 2 - 1) * 0.5 + 0.5
	end
end
_SL.Easing.outBounce = function(t)
	if t < 1 / 2.75 then
		return 7.5625 * t * t
	elseif t < 2 / 2.75 then
		t = t - 1.5 / 2.75
		return 7.5625 * t * t + 0.75
	elseif t < 2.5 / 2.75 then
		t = t - 2.25 / 2.75
		return 7.5625 * t * t + 0.9375
	else
		t = t - 2.625 / 2.75
		return 7.5625 * t * t + 0.984375
	end
end
_SL.Easing.inBounce = function(t)
	return 1 - outBounce(1 - t)
end
_SL.Easing.inOutBounce = function(t)
	if t < 0.5 then
		return inBounce(t * 2) * 0.5
	else
		return outBounce(t * 2 - 1) * 0.5 + 0.5
	end
end
_SL.Easing.outInBounce = function(t)
	if t < 0.5 then
		return outBounce(t * 2) * 0.5
	else
		return inBounce(t * 2 - 1) * 0.5 + 0.5
	end
end
_SL.Easing.inSine = function(x)
	return 1 - cos(x * (pi * 0.5))
end
_SL.Easing.outSine = function(x)
	return sin(x * (pi * 0.5))
end
_SL.Easing.inOutSine = function(x)
	return 0.5 - 0.5 * cos(x * pi)
end
_SL.Easing.outInSine = function(t)
	if t < 0.5 then
		return outSine(t * 2) * 0.5
	else
		return inSine(t * 2 - 1) * 0.5 + 0.5
	end
end

local function outElasticInternal(t, a, p)
	return a * pow(2, -10 * t) * sin((t - p / (2 * pi) * asin(1 / a)) * 2 * pi / p) + 1
end
local function inElasticInternal(t, a, p)
	return 1 - outElasticInternal(1 - t, a, p)
end
local function inOutElasticInternal(t, a, p)
	return t < 0.5 and 0.5 * inElasticInternal(t * 2, a, p) or 0.5 + 0.5 * outElasticInternal(t * 2 - 1, a, p)
end
local function outInElasticInternal(t, a, p)
	return t < 0.5 and 0.5 * outElasticInternal(t * 2, a, p) or 0.5 + 0.5 * inElasticInternal(t * 2 - 1, a, p)
end

_SL.Easing.inElastic = with2params(inElasticInternal, 1, 0.3)
_SL.Easing.outElastic = with2params(outElasticInternal, 1, 0.3)
_SL.Easing.inOutElastic = with2params(inOutElasticInternal, 1, 0.3)
_SL.Easing.outInElastic = with2params(outInElasticInternal, 1, 0.3)

local function inBackInternal(t, a)
	return t * t * (a * t + t - a)
end
local function outBackInternal(t, a)
	t = t - 1
	return t * t * ((a + 1) * t + a) + 1
end
local function inOutBackInternal(t, a)
	return t < 0.5 and 0.5 * inBackInternal(t * 2, a) or 0.5 + 0.5 * outBackInternal(t * 2 - 1, a)
end
local function outInBackInternal(t, a)
	return t < 0.5 and 0.5 * outBackInternal(t * 2, a) or 0.5 + 0.5 * inBackInternal(t * 2 - 1, a)
end

_SL.Easing.inBack = with1param(inBackInternal, 1.70158)
_SL.Easing.outBack = with1param(outBackInternal, 1.70158)
_SL.Easing.inOutBack = with1param(inOutBackInternal, 1.70158)
_SL.Easing.outInBack = with1param(outInBackInternal, 1.70158)

-- some internals expect functions, but some eases are tables with metatable magic, so use a wrapper to make the game think it's operating on a function instead
-- kinda ugly but it works
_SL.Easing.wrap = function(fn)
    return function(t) return fn(t) end
end