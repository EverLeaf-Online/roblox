local PayloadBounds = require("../src/shared/Validation/PayloadBounds")
assert(PayloadBounds.IsBounded({ ItemId = "tonic", Quantity = 1 }), "normal payload")
assert(not PayloadBounds.IsBounded({ Name = string.rep("x", 129) }), "oversized string rejected")
local deep = { a = { b = { c = { d = { e = true } } } } }
assert(not PayloadBounds.IsBounded(deep), "excessive nesting rejected")
print("payload validation tests passed")
