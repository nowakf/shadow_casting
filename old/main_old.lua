local back, front

local cnt = 0
function take_pic()
	cnt = cnt + 1
	love.graphics.captureScreenshot(cnt .. '.png')
end

local shaders = {}
function load_shaders()
	for _, filename in ipairs(love.filesystem.getDirectoryItems('shaders')) do
		local basename = filename:match('(.*).glsl')
		if basename then
			local src = assert(io.open('shaders/' .. filename)):read('*a')
			shaders[basename] = love.graphics.newShader(src)
		end
	end
end


function voronoi_seed(prev, out)
	love.graphics.setShader(shaders['voronoi_seed'])
	shaders['voronoi_seed']:send('u_input_tex', prev)
	love.graphics.setCanvas(out)
	love.graphics.draw(prev)
	love.graphics.setCanvas()
	love.graphics.setShader()
	return prev, out
end

function jump_flood(prev, out)
	local w, h = love.graphics.getDimensions()
	local passes = math.ceil(math.log(math.max(w, h)) / math.log(2.0))
	love.graphics.setShader(shaders['jump_flood_pass'])
	local x = love.mouse.getPosition() / w * (passes-1)
	for i=0,passes-1 do
		local offset = 2 ^ (passes - i - 1) 
		shaders['jump_flood_pass']:send('u_level', i)
		shaders['jump_flood_pass']:send('u_max_steps', passes)
		shaders['jump_flood_pass']:send('u_offset', offset)
		shaders['jump_flood_pass']:send('u_input_tex', prev)
		--swap
		love.graphics.setCanvas(out)
		love.graphics.draw(prev)
		prev, out = out, prev
	end
	love.graphics.setShader()
	love.graphics.setCanvas()
	return prev, out
end

function distance_field(prev, out)
	love.graphics.setShader(shaders['distance_field'])
	love.graphics.setCanvas(out)
	love.graphics.draw(prev)
	love.graphics.setCanvas()
	love.graphics.setShader()
	return prev, out
end

lights = {{0.5, 0.5}, {0.5, 1.0}}

function global_illumination(distance_field, emitters, out)
	shaders['global_illumination']:send('u_distance_data', distance_field);
	shaders['global_illumination']:send('u_scene_data', emitters);
	shaders['global_illumination']:send('u_lights', unpack(lights));
	love.graphics.setShader(shaders['global_illumination'])
	love.graphics.setCanvas(out)
	love.graphics.draw(distance_field)
	love.graphics.setCanvas()
	love.graphics.setShader()
	return out
end

pts = {}
vels = {}

function love.load()
	love.graphics.setDefaultFilter('nearest')
	love.mouse.setVisible(false)
	load_shaders()
	for i=0, 100 do
		pts[i] = {0, 0}
		vels[i] = {math.random(), math.random()}
	end
	local w, h = love.graphics.getDimensions()
	a = love.graphics.newCanvas(w/3, h/3)
	b = love.graphics.newCanvas(w/3, h/3)
	c = love.graphics.newCanvas(w/3, h/3)
end


function love.update()
	local w, h = love.graphics.getDimensions()
	--for i, pt in ipairs(pts) do
	--	local x, y = pts[i][1], pts[i][2]
	--	if x < 0 or x > w or y < 0 or y > h then
	--		pts[i] = {0, 0}
	--	end
	--	pts[i][1] = pts[i][1] + vels[i][1]
	--	pts[i][2] = pts[i][2] + vels[i][2]
	--end
end


function draw_circles(out)
	local mx, my = love.mouse.getPosition()
	love.graphics.setCanvas(out)
	love.graphics.clear({0,0,0,0})
	love.graphics.push()
	love.graphics.scale(0.33, 0.33)
	local mx, my = love.mouse.getPosition()
	local w, h = love.graphics.getDimensions()
	love.graphics.setColor({1,0,0})
	love.graphics.circle('fill', w/3, h/2, mx / w * 100)
	love.graphics.setColor({0,1,0})
	love.graphics.circle('fill', w/2, 1, 3)
	love.graphics.setColor({0,0,0})
	for _, pt in ipairs(pts) do
--		love.graphics.circle('fill', pt[1], pt[2], 12)
	end
	love.graphics.pop()
	love.graphics.setCanvas()
	love.graphics.setColor({1,1,1})
	return out
end

function love.draw()
	a = draw_circles(a)
	a, b = voronoi_seed(a, b)
	a, b = jump_flood(b, a)
	a, b = distance_field(a, b)
	c = draw_circles(c)
	local final = global_illumination(b, c, a)
	love.graphics.draw(a, 0)
	love.graphics.draw(b, 200)
	love.graphics.draw(c, 500)
	love.graphics.draw(final, 500, 300)
	love.graphics.print(love.timer.getFPS())
	love.graphics.setShader()
end
