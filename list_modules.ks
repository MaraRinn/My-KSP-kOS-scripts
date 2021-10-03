runOncePath("lib/vessel_operations").

function comparator {
    parameter module.
    for fieldName in module:AllFieldNames() {
        if fieldName:contains("biome") {
            return True.
        }
    }
    for actionName in module:AllActionNames() {
        if actionName:contains("biome") {
            return True.
        }
    }
    for eventName in module:AllEventNames() {
        if eventName:contains("biome") {
            return True.
        }
    }
    return False.
}

local things is ModuleSMatching(comparator@).
print things.
