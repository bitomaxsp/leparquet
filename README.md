# leparquet
LeParquet is a tool to calculate amount of parquet boards used to layout in your rooms.

Q: Why? 

A: Because I couldn't find any reasonable tool that gives me sane results which I can use for my flat.

## If you are a regular person

You need to have [swift](https://docs.swift.org) installed. Then just run `swift run leparquet deck --verbose config.yaml`

`config.yaml` should contain you room setup

## If you are a developer

You know what to do. 

Hint: `swiftformat . && swift run leparquet deck --verbose config.yaml`

## Room shape consideration

Leparquet assumes that the room under layout (RUL) is a rectangle in common case. If your room slightly differs from rectangle you need to take into account yourself. You can do it by virtually imagine that it is rectangle and use biggest sizes from what you measured. Then you account it during layout by shortening certain boards. This approach is only valid for small amount of "not being a rectangle".

Leparquet does not account for any possible cutout (keep out) areas in your room, i.e if you have rectangle (or any other shape) in the middle of the room for example. There is a plan to add it.

## Frames and origins

Leparquet always assumes that coordinate frame origin for the room is in top left corner. Width axis direction is to the right of the room. Height axis direction it to the bottom of the room. Currently layout direction is only from left to right, i.e. in positive width axis direction.

## Taking room measurements
    
Usually rooms are not precise rectangles. One side maybe 1-2 cm greater or less than the other. If you measure your room sizes make sure you use largest of all possible sizes per each side. Rooms are entered as width and height, where width is a direction along which board are set on the floor. Height is a direction orthogonal to width (See frames and origins). If you room is long (more than 5m) try to measure it in more that 2 places per each pair of sides. This is needed to avoid the situation where room waist could be larger or smaller than the same distance measured closer to one of the ends of the room.

### Door rectangles measurements

Leparquet can take door passages into account. You specify door in the config file. It is very important how to do measurements of the door passages. You need to measure 3 parameters:

1. Door passage origin point. You measure it from coordinate frame origin (top left corner) along the edge where door is. Measurement must be taken from the wall. 
2. Width of the passage. You specify width ALONG the edge. For example, if the door is at the top room edge, you measure width from left to right. If the door is on the right or left edge, you measure width from top to bottom.
3. Height of the passage. You measure height in lateral to width direction.

All measurements must be in mm in the config file.


### Cutout areas measurements

Not supported so far.

## Layout direction

Layout direction is always from left to the right, top to bottom.

# Contributions

They are welcome. Feel free to submit a PR.

# Disclaimer

Certainly, you use it at your own risk.
