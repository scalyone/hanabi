function logs(...)
    log(table.concat(mapArray({...}, logString)," "))
end

function tableSize(table)
    local count = 0
    for _,_ in pairs(table) do
        count = count + 1
    end
    return count
end

function concatTables(first, second)
    for _,entry in ipairs(second) do
        table.insert(first, entry)
    end
    return first
end

function mapTable(table, fn)
    local t = {}
    for k,v in pairs(table) do
        t[k] = fn(v)
    end
    return t
end

function mapArray(array, fn)
    local t = {}
    for _,v in ipairs(array) do
        table.insert(t, fn(v))
    end
    return t
end

function filter(table, pred)
    local t = {}
    for k,v in pairs(table) do
        if pred(v) then
            t[k] = v
        end
    end
    return t
end

function filterArray(array, pred)
    local t = {}
    for _,v in ipairs(array) do
        if pred(v) then
            table.insert(t, v)
        end
    end
    return t
end

function bitwiseOr(ints)
    local res = 0
    for _,a in pairs(ints) do
        res = bit32.bor(res, a)
    end
    return res
end

function bitwiseAnd(ints)
    local res = nil
    for i,a in pairs(ints) do
        if i == 1 then
            res = a
        else
            res = bit32.band(res, a)
        end
        res = bit32.bor(res, a)
    end
    return res
end

function pluck(key)
    return function(table)
        return table[key]
    end
end

function noDuplicatesArray(array)
    local hash = {}
    local res = {}
    for _,v in ipairs(array) do
        if not hash[v] then
            table.insert(res, v)
            hash[v] = true
        end
    end
    return res
end

function reverseArray(array)
    rev = {}
    for i=#array, 1, -1 do
        rev[#rev+1] = array[i]
    end
    return rev
end

-- return a function that has the first two arguments in reverse order
function flip(fn)
    return function(a,b,...)
        return fn(b,a,...)
    end
end

-- Flips the order of the first two curried function calls in a curried
-- function
function curryFlip(fn)
    return function(...)
        local argsA = {...}
        return function(...)
            return fn(...)(table.unpack(argsA))
        end
    end
end

-- Function application that takes the value first and the function
-- second
function applyFlipped(...)
    local args = {...}
    return function(fn)
        return fn(table.unpack(args))
    end
end