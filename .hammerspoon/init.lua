    
-- in-situ reversal
function reverse(t)
  local n = #t
  local i = 1
  while i < n do
    t[i],t[n] = t[n],t[i]
    i = i + 1
    n = n - 1
  end
end

function reversedPairsByKeys (t, f)
      local a = {}
      for n in pairs(t) do table.insert(a, n) end
      table.sort(a, f)
      reverse(a)
      local i = 0      -- iterator variable
      local iter = function ()   -- iterator function
        i = i + 1
        if a[i] == nil then return nil
        else return a[i], t[a[i]]
        end
      end
      return iter
    end

function pairsByKeys (t, f)
      local a = {}
      for n in pairs(t) do table.insert(a, n) end
      table.sort(a, f)
      local i = 0      -- iterator variable
      local iter = function ()   -- iterator function
        i = i + 1
        if a[i] == nil then return nil
        else return a[i], t[a[i]]
        end
      end
      return iter
    end

next_size = {[1.00]=0.75,
	 [0.75]=0.66,
	 [0.66]=0.50,
	 [0.50]=0.33,
	 [0.33]=0.25,
	 [0.25]=0.25}

next_size_larger = {
	 [0.25]=0.33,
	 [0.33]=0.50,
	 [0.50]=0.66,
	 [0.66]=0.75,
	 [0.75]=1.00,
	[1.00]=1.00,
 }

function shrink_vertically() 
  local f = hs.window.focusedWindow():frame()
  local screen_height = hs.window.focusedWindow():screen():frame().h;
  local window_height = f.h
   local old_y = f.y
	for current_h, next_h in reversedPairsByKeys(next_size) do
		if (window_height >= (screen_height * current_h)) then
			window_height = next_h * screen_height
			break
		end
	end
	new_size =hs.window.focusedWindow():setSize(f.w, window_height);
end



function grow_horizontally() 
  local f = hs.window.focusedWindow():frame()
  local screen_width = hs.window.focusedWindow():screen():frame().w;
  local window_width = f.w

	for current_w, next_w in pairsByKeys(next_size_larger) do
		if (window_width <= (screen_width * current_w)) then
			window_width = next_w * screen_width
			break
		end
	end
	f.w = window_width;
	if (f.x+f.w > screen_width) then
		f.x = screen_width - f.w
	end
  	hs.window.focusedWindow():setFrame(f)
end


function grow_vertically() 
  local f = hs.window.focusedWindow():frame()
  local screen_height = hs.window.focusedWindow():screen():frame().h;
  local window_height = f.h
  for current_h, next_h in pairsByKeys(next_size_larger) do
	  if (window_height <= (screen_height * current_h)) then
			window_height = screen_height * next_h
			break
		end
	end
	f.h = window_height;
	if (f.y+f.h > screen_height) then
		f.y = screen_height - f.h
	end
  	hs.window.focusedWindow():setFrame(f)
end



function shrink_horizontally()
  local f = hs.window.focusedWindow():frame()
  local screen_width = hs.window.focusedWindow():screen():frame().w;
  local window_width = f.w

	for current_w, next_w in reversedPairsByKeys(next_size) do
		if (window_width >= (screen_width * current_w)) then
			window_width = next_w * screen_width
			break
		end
	end
	new_size =hs.window.focusedWindow():setSize( window_width,f.h);
	-- If the window can't get any smaller, it's time to go full screen
	end 



hs.hotkey.bind({"cmd", "alt", "ctrl"}, "Left", function()
  local f = hs.window.focusedWindow():frame()
  local screen_width = hs.window.focusedWindow():screen():frame().w;
	-- if we're near the left side ,reduce the window width
	-- if we're on the left side, warp over to the right
	if (f.x ==0) then 
		--shrink_horizontally()
		-- now we need to refresh the frame object
  		f = hs.window.focusedWindow():frame()
		--f.x = screen_width - f.w
	elseif (f.x >= f.w) then
	-- move the window over to the left by one width
	f.x = f.x - f.w
	else
	f.x = 0
	end 
  hs.window.focusedWindow():setFrame(f)
end)

hs.hotkey.bind({"cmd", "alt", "ctrl"}, "Right", function()
  local f = hs.window.focusedWindow():frame()
  local screen_width = hs.window.focusedWindow():screen():frame().w;
	-- if we're near the left side ,reduce the window width
	-- if we're on the left side, warp over to the right
	if (f.x +f.w  ==screen_width) then 
		--f.x = 0
		
  		hs.window.focusedWindow():setFrame(f)
--		shrink_horizontally()
		-- now we need to refresh the frame object
  		f = hs.window.focusedWindow():frame()
		f.x = screen_width - f.w
	elseif (f.x + f.w <= screen_width) then
	-- move the window over to the left by one width
	f.x = f.x + f.w
	else
	f.x = screen_width - f.w
	end 

	if ((f.x + f.w) > screen_width) then
		f.x = screen_width - f.w
	end
  hs.window.focusedWindow():setFrame(f)
end)


hs.hotkey.bind({"cmd", "alt"}, "Right", function()
  local f = hs.window.focusedWindow():frame()
  local screen_width = hs.window.focusedWindow():screen():frame().w;
	-- if we're near the left side ,reduce the window width
	-- if we're on the left side, warp over to the right
		grow_horizontally()
end)

hs.hotkey.bind({"cmd", "alt"}, "Left", function()
  local f = hs.window.focusedWindow():frame()
  local screen_width = hs.window.focusedWindow():screen():frame().w;
	-- if we're near the left side ,reduce the window width
	-- if we're on the left side, warp over to the right
		shrink_horizontally()

end)

hs.hotkey.bind({"cmd", "alt"}, "Down", function()
  local f = hs.window.focusedWindow():frame()
  local screen_height = hs.window.focusedWindow():screen():frame().h;
  local screen_top = hs.window.focusedWindow():screen():frame().y;
		grow_vertically()
end)
hs.hotkey.bind({"cmd", "alt"}, "Up", function()
  local f = hs.window.focusedWindow():frame()
  local screen_height = hs.window.focusedWindow():screen():frame().h;
  local screen_top = hs.window.focusedWindow():screen():frame().y;
		shrink_vertically()
end)

hs.hotkey.bind({"cmd", "alt", "ctrl"}, "Up", function()
  local f = hs.window.focusedWindow():frame()
  local screen_height = hs.window.focusedWindow():screen():frame().h;
  local screen_top = hs.window.focusedWindow():screen():frame().y;

	if (f.y == screen_top) then
		--shrink_vertically()
		-- now we need to refresh the frame object
  		f = hs.window.focusedWindow():frame()
--		f.y = (screen_height + screen_top) - f.h
	elseif (f.y >= f.h) then
		f.y = f.y - f.h
	else
		f.y = screen_top
	end 

  hs.window.focusedWindow():setFrame(f)
end)

hs.hotkey.bind({"cmd", "alt", "ctrl"}, "Down", function()
  local f = hs.window.focusedWindow():frame()
  local screen_height = hs.window.focusedWindow():screen():frame().h;
  local screen_top = hs.window.focusedWindow():screen():frame().y;
	if (f.y+f.h == (screen_height+screen_top)) then
--		f.y = screen_top
  		hs.window.focusedWindow():setFrame(f)
--		shrink_vertically()
		-- now we need to refresh the frame object
  		f = hs.window.focusedWindow():frame()
		f.y = screen_height + screen_top - f.h
	elseif (f.y+f.h <= screen_height) then
		f.y = f.y + f.h
	else
		f.y = screen_height+screen_top - f.h
	end 

	if ((f.y + f.h) > screen_height) then
		f.y = screen_top +screen_height - f.h
	end
  hs.window.focusedWindow():setFrame(f)
end)

