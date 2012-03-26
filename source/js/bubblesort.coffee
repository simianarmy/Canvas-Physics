bubbleSort = (arr, start, end) ->
  for i in [end-1..start]
    for j in [start..i]
      if arr[j+1] < arr[j]
        tmp = arr[j+1]
        arr[j+1] = arr[j]
        arr[j] = tmp

arr = []
for i in [0..1000]
  arr.push Math.round(Math.random() * 100)
console.log "array = #{arr.join(',')}"
bubbleSort arr, 0, arr.length-1
console.log "array = #{arr.join(',')}"