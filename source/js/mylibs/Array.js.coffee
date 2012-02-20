# Array object extensions

if typeof Array.prototype.min != 'function'
  Array::min = ->
    res = @[0]
    for i in [1...@length]
      res = Math.min(res, @[i])
    res