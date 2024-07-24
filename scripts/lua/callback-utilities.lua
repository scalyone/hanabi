---------------------------------------------------------------------
-------------- [[ Callback Thunk Utilities ]] -----------------------
---------------------------------------------------------------------
--
-- Utility functions that make working with callbacks in an api much
-- nicer. To use these function you must first turn a callback into
-- a callback_thunk.
--
-- A callback thunk has the following signature:
--    function(callback) -> void
--    where callback is either nil or a function that can be invoked
--    with some future result.

-- Take its arguements and wraps them in a callback_thunk
function liftValuesToCallback(...)
    local args = {...}
    return function(callback)
        resolveCallback(callback, table.unpack(args))
    end
end

function liftFunctionTocallback(fn, ...)
    local args = {...}
    return function(callback)
        local results = {fn(table.unpack(args))}
        resolveCallback(callback, table.unpack(results))
    end
end

-- Shape preserving map over a callback_thunk
function mapCallback(map_fn, callback_thunk)
    return function(callback)
        callback_thunk(function(...)
            resolveCallback(callback, map_fn(...))
        end)
    end
end

function mapCallbackFlipped(callback_thunk, map_fn)
    return flip(mapCallback)
end

-- Implement bind for callback_thunks. Think of this as a map 
-- followed by a join. Since join is pretty much only useful in this
-- context, we don't implement it separately
function bindCallback(callback_thunk, bind_fn)
    return function(callback)
        callback_thunk(function(...)
            local thunk = bind_fn(...)
            if thunk ~= nil and type(thunk) == "function" then
                thunk(callback)
            end
        end)
    end
end

-- Kleisli Composition specific to functions that return callback_thunks
-- The pipe keyword here means that composition works in the reverse
-- direction (Its arguements are flipped).
--
-- If `()` is function invocation, `·` is a right-associative compose,
-- and `|` is a left-associative pipe, then the following are equivalent
--    c(x) = h(g(f(x)))
--    c = h·g·f
--    c = f|g|h
--
-- The idea is that if f, g, & h are all well named, reading them from
-- left to right should make sense. 
function kleisliCallbackPipe(bind_fn_array)
    return function(...)
        local bound = liftValuesToCallback(...)
        for _,call in ipairs(bind_fn_array) do
                bound = bindCallback(bound, call)
        end
        return bound
    end
end

-- Same as bindCallback, only the second paramter is an array of bind_fn
function bindKleisliCallbackPipe(callback_thunk, bind_fn_array)
    return bindCallback(callback_thunk, kleisliCallbackPipe(bind_fn_array))
end

-- A wrapper around kleisliCallbackPipe, that invokes the returned
-- function with an arguement, returning a callback_thunk instead of
-- the composition.
-- This makes a pipe read more naturally, as everything (including 
-- the starting value) "moves" from the left to the right.
function kleisliPipeOn(init, bind_fn_array)
    return kleisliCallbackPipe(bind_fn_array)(init)
end

-- Same as kleisliPipeOn, but lets you calculate some initial value at
-- the moment the callback_thunk is run
function kleisliPipeOnLazy(thunk_init, bind_fn_array)
    -- This can't be written point-free, because we're introducing a lazy
    -- value. thunk_init is only evaluated as part of the join on the callback.
    return function(callback)
        kleisliCallbackPipe(bind_fn_array)(thunk_init())(callback)
    end
end

-- Utility that will invoke a table of callback_thunks.
--
-- It calls them all in parallel and stores the results of each
-- callback in a shape-preserving table.
-- 
-- This isn't protective against errors (neither is TTS, tbf), so if
-- any of the given calls don't return, this will silently fail. (At
-- least for now)
function parallelCallback(callTable)
    return function(callback)
        local totalCount = tableSize(callTable)
        local resultCount = 0
        local results = {}

        for key,call in pairs(callTable) do
            call(function(v)
                resultCount = resultCount + 1
                results[key] = v
                if resultCount == totalCount and callback ~= nil then
                    callback(results)
                end
            end)
        end
    end
end

-- Helper function for seriesCallback that merges results into
-- a table using the given key. The third arguement is curied
-- to make it cleaner below. 
function joinWithTable(callback_thunk, key)
    return function(acc_table)
        return mapCallback(
            function(...)
                local result = {...}
                if #result == 1 then
                    result = result[1]
                end
                acc_table[key] = result
                return acc_table
            end,
            callback_thunk
        )
    end
end

-- Utility function, the same as parallel callback, but done in series
-- instead. Expects an array and returns a callback_thunk wrapping an 
-- array of the same shape.
function seriesCallback(callArray)
    local bound = liftValuesToCallback({})

    -- For every entry in callArray, bind it with whatever has been
    -- accumulated so far
    for key, call in ipairs(callArray) do
        bound = bindCallback(bound, joinWithTable(call, key))
    end

    return bound
end

-- Helper function that will resolve a callback with some arguements.
-- does nothing if the callback is nil
function resolveCallback(callback, ...)
    if callback ~= nil then
        callback(...)
    end
end

-- Utility function most useful when used in a kleisliCallbackPipe
--
-- The `tap` preface here means that the given value(s) are eventually
-- passed on/returned. That means exec_fn's return value(s) are ignored.
-- The only use of tapFunction then is to perform some side effect.
function tapFunction(exec_fn)
    return function (...)
        local args = {...}
        return function (callback)
            exec_fn(table.unpack(args))
            resolveCallback(callback, table.unpack(args))
        end
    end
end

-- Utility function most useful when used in a kleisliCallbackPipe
--
-- Print the current value and tag it with a custom log-value
function tapLog(log_value)
    return function (...)
        local args = {...}
        return function (callback)

            log(logString(log_value) .. ":\n" .. logString(args))
            resolveCallback(callback, table.unpack(args))
        end
    end
end


-- Utility function most useful when used in a kleisliCallbackPipe
--
-- The `tap` preface here means that the given value(s) are eventually
-- passed on/returned. That means callback_thunk is given a callback,
-- we wait for the callback to complete, but ignore any arguements
-- given.
-- The only use of tapCallback then is to perform some side effect and
-- wait for them to finish before continueing.
function tapCallback(callback_thunk)
    return function (...)
        local args = {...}
        return function (callback)
            callback_thunk(function()
                resolveCallback(callback, table.unpack(args))
            end)
        end
    end
end

-- Utility function most useful when used in a kleisliCallbackPipe
--
-- Ignore the output of a bindable function.
function tapBind(bind_fn)
    return function (...)
        return tapCallback(bind_fn(...))(...)
    end
end

-- Utility function most useful when used in a kleisliCallbackPipe
--
-- Shape preserving map over functions that return callback_thunks
function mapLiftCallback(map_fn)
    return function (...)
        local args = {...}
        return function (callback)
            local transform = {map_fn(table.unpack(args))}
            resolveCallback(callback, table.unpack(transform))
        end
    end
end

-- Utility function most useful when used in a kleisliCallbackPipe
--
-- Only resolve the given callback if the predicate passed in
-- returns true. Think of this as an early return for 
-- kleisliCallbackPipes
function continueIf(pred)
    return function (...)
        local args = {...}
        return function (callback)
            if pred(table.unpack(args)) then
                resolveCallback(callback, table.unpack(args))
            end
        end
    end
end

-- Utility function most useful when used in a kleisliCallbackPipe
--
-- The returned callback_thunk additionally remembers and returns the
-- value(s) the supplied function it was given
function remember(bind_fn)
    return function (...)
        local args = {...}
        return mapCallback(
            function(...)
                return table.unpack(
                    noDuplicatesArray(
                        concatTables({...}, args)
                    )
                )
            end,
            bind_fn(table.unpack(args))
        )
    end
end