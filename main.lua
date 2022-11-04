local SCALE = 2/3

local shaders = {}
local buffers = {}
local u_lights = {}
local cloud_map 
local circle_normal = love.graphics.newImage('images/circle_normal.png')

function load_volume(dirpath)
	local images = {}
	for _, filename in ipairs(love.filesystem.getDirectoryItems(dirpath)) do
		table.insert(images, dirpath .. '/' .. filename)
	end
	return love.graphics.newVolumeImage(images)
end


local cnt = 0
function take_pic()
	cnt = cnt + 1
	love.graphics.captureScreenshot(cnt .. '.png')
end

function load_shaders(dirpath)
	local shaders = {}
	for _, filename in ipairs(love.filesystem.getDirectoryItems(dirpath)) do
		local basename = filename:match('(.*).glsl')
		if basename then
			local src = assert(io.open(dirpath .. '/' .. filename)):read('*a')
			shaders[basename] = love.graphics.newShader(src)
		end
	end
	return shaders
end
function love.load()
	cloud_map = load_volume('images/clouds')
	cloud_map:setFilter('nearest')
	local w, h = love.graphics.getDimensions()
	love.resize(w, h)
	shaders = load_shaders('shaders')
end

function draw_emitters()
	local w, h = love.graphics.getDimensions()
	local mx, my = love.mouse.getPosition()
	--mmm?
	local emitters = {
		{mx, my, 50},
	}
	u_lights = {}
	for _, e in ipairs(emitters) do
		table.insert(u_lights, {e[1] / w, e[2] / h})
	end
end
function draw_occluders()
	love.graphics.rectangle('fill', 500, 300, 100, 100)
	love.graphics.rectangle('fill', 800, 300, 100, 100)
	love.graphics.rectangle('fill', 300, 500, 100, 100)
	love.graphics.draw(circle_normal, 300, 300, love.timer.getTime()/2, 0.2)
end

function draw_scene()
	love.graphics.setCanvas(buffers[3])
	love.graphics.push()
	love.graphics.scale(SCALE, SCALE)
	draw_emitters()
	draw_occluders()
	love.graphics.pop()
	love.graphics.setCanvas()
end

function jump_flood()
	--prep seed
	love.graphics.setShader(shaders['seed'])
	love.graphics.setCanvas(buffers[1])
	love.graphics.draw(buffers[3])
	--

	local w, h = love.graphics.getDimensions()
	local passes = math.ceil(math.log(math.max(w, h)) / math.log(2.0))
	love.graphics.setShader(shaders['jflood'])
	for i=0,passes-1 do
		local offset = 2 ^ (passes - i - 1)
		shaders['jflood']:send('u_offset', offset)
		love.graphics.setCanvas(buffers[(i+1)%2+1])
		love.graphics.draw(buffers[i%2+1])
	end
	love.graphics.setCanvas()
	love.graphics.setShader()
	--make sure canvases are in right slots
	buffers[1], buffers[2] = buffers[passes%2+1], buffers[(passes-1)%2+1]
end
local t = 0
function global_illumination(voronoi_map, normal_map)
	t = t + 0.01
	love.graphics.setShader(shaders['gi'])
	shaders['gi']:send('u_voronoi_map', voronoi_map)
	shaders['gi']:send('u_cloud_map', cloud_map)
	shaders['gi']:send('u_time', math.sin(t))
	shaders['gi']:send('u_lights', unpack(u_lights))
	love.graphics.setCanvas(buffers[2])
	love.graphics.draw(buffers[3])
	love.graphics.setCanvas()
	love.graphics.setShader()
end

function clear_buffers(buffers) 
	for _, b in ipairs(buffers) do
		love.graphics.setCanvas(b)
		love.graphics.clear({0, 0, 0, 0})
	end
	love.graphics.setCanvas()
end

function love.resize(w, h)
	buffers =  {
		 love.graphics.newCanvas(w*SCALE, h*SCALE),
		 love.graphics.newCanvas(w*SCALE, h*SCALE),
		 love.graphics.newCanvas(w*SCALE, h*SCALE),
	}
	clear_buffers(buffers)
end

function love.update()
end

function love.draw()
	clear_buffers(buffers)
	draw_scene()
	jump_flood()
	--love.graphics.draw(buffers[3], 0, 0, 0, 1/SCALE)
	global_illumination(buffers[1], buffers[3])
	love.graphics.draw(buffers[2], 0, 0, 0, 1/SCALE)
	love.graphics.print(love.timer.getFPS())
	--take_pic()
end
