--#region GLOBAL VARIABLES

expomod = {}
expomod.gameui = {
	model=2,
}
expomod.modname = minetest.get_current_modname()
expomod.modpath = minetest.get_modpath(expomod.modname)
expomod.modstorage = minetest.get_mod_storage()


print ('###############################################')
print ('# EXPO START')
print ('# minetest expomod.modname :' .. expomod.modname)
print ('# private expomod.modname :' .. "expo")
print ('# expomod.modpath :' .. expomod.modpath)

expomod.gameui.model = expomod.modstorage:get_int("expo_model", expomod.gameui.model)
if (expomod.gameui.model < 0 or expomod.gameui.model > 4) then
	expomod.gameui.model = 0
end

expomod.path_to_textures = expomod.modpath .. DIR_DELIM .. "textures" .. DIR_DELIM

expomod.display_formspec_name = "expo" .. ":ExpoDisplay_formspec_"
expomod.display_entity_name = "expo" .. ':ExpoDisplay'
expomod.display_item_name  = "expo" .. ":ExpoDisplay_item"
expomod.display_remote_item_name = "expo" .. ":ExpoDisplay_remote_item"
expomod.display_remote_item_formspec_name = "expo" .. ":ExpoDisplay_remote_formspec_"

expomod.display_max_size = 50
expomod.display_min_size = 1
expomod.display_max_textures = 30

expomod.displays = {}
expomod.nextDisplayIndex = 0
expomod.insecure_environment = nil



--#endregion GLOBAL VARIABLES


function  expomod.print_warn(msg)
    print('\27[93m'..msg ..'\27[0m')
end

if minetest.request_insecure_environment then
	 expomod.insecure_environment = minetest.request_insecure_environment()
	 if not expomod.insecure_environment then
        expomod.print_warn("[WARNING] Presentation requires an insecure environment to download textures. Add 'secure.trusted_mods = " .. expomod.modname .. "' to the minetest.conf to enable this feature.")
     else
        --override package path to recoginze external folder
        local old_path = expomod.insecure_environment.package.path
        local old_cpath = expomod.insecure_environment.package.cpath
        expomod.insecure_environment.package.path = expomod.insecure_environment.package.path.. ";" .. expomod.modpath .. "/external/?.lua"
        expomod.insecure_environment.package.cpath = expomod.insecure_environment.package.cpath.. ";" .. expomod.modpath .. "/external/?.so"
        --overriding require to insecure require to allow modules to load dependencies
        local old_require = require
        require = expomod.insecure_environment.require

        --load modules
        --Http  = require("socket.http")
        --Ltn12 = require("ltn12")

        --reset changes
        require = old_require
        expomod.insecure_environment.package.path = old_path
        expomod.insecure_environment.package.cpath = old_cpath
     end
end

minetest.register_privilege('expopriv', {
    description = "Can use and edit expo expomod.displays"
})

local DisplayEntity = {
    initial_properties = {
        hp_max = 1,
        physical = true,
        collide_with_objects = false,
        collisionbox = {-.5, -.5, -.1, .5, .5, .1},
        visual = "mesh",
        mesh = "display.obj",
        visual_size = {x = 1, y = 1},
        textures = {"default.jpg"},
        spritediv = {x = 1, y = 1},
        initial_sprite_basepos = {x = 0, y = 0},
		nametag="",
		infotext="",
		
		

    },

    id = -1,
    proportions_x = 1.0,
    proportions_y = 1.0,
    size = 1.0,
    allow_changing = false,

    texture_names ={"/expo/expo.jpg"},
    textures_index = 1,
    textures_count = 1,
	_expoid="expodisplay",
	_altdescription="",
	


}

function DisplayEntity:change_textures_to(textures)
    self.texture_names = textures;
    self.current_index = 1
    self:update_texture()
end

function DisplayEntity:set_proportions(x,y)
    self.proportions_x = x;
    self.proportions_y = y;
    self:update_size()
end

function DisplayEntity:set_size(new_size)
    self.size = new_size
    self:update_size()
end

function  DisplayEntity:update_texture()
    local url = self.texture_names[self.textures_index]
    local name = url:match( "([^/]+)$")
    print ("display entity :" .. name)
    self.object:set_properties({textures = {name}})
end

function  DisplayEntity:update_size()

    local size_x = self.size * (self.proportions_x / self.proportions_y);
    local size_y = self.size;
    local half_x = size_x * 0.5
    local half_y = size_y * 0.5

    local yaw = self.object:get_yaw()

    if yaw == 0 then
        self.object:set_properties({
            visual_size = {x = size_x, y = size_y},
            collisionbox = {-half_x, -half_y, -.1, half_x, half_y, .1}
        })
    elseif yaw >= math.pi / 5 and yaw <= math.pi / 3 then
		self.object:set_properties({
				visual_size = {x = size_x, y = size_y},
				collisionbox = {-half_x * 0.7, -half_y, -half_x * 0.7, half_x* 0.7, half_y, half_x* 0.7}
			})
	elseif yaw >= ((math.pi / 2)+ (math.pi/8)) and yaw <= ((math.pi / 2)+ (math.pi / 4) + (math.pi/8)) then
		self.object:set_properties({
				visual_size = {x = size_x, y = size_y},
				collisionbox = {-half_x * 0.7, -half_y, -half_x * 0.7, half_x* 0.7, half_y, half_x* 0.7}
			})
	else	
        self.object:set_properties({
            visual_size = {x = size_x, y = size_y},
            collisionbox = {-.1, -half_y, -half_x, .1, half_y, half_x}
        })
    end
end

function DisplayEntity:on_activate(staticdata, dtime_s)

    if staticdata ~= nil and staticdata ~= "" then
        local data = minetest.parse_json(staticdata)

        self.id = data.id
        self.proportions_x = data.proportions_x
        self.proportions_y = data.proportions_y
        self.size = data.size
        self.texture_names = data.texture_names
        self.textures_index = data.textures_index
        self.textures_count = data.textures_count
        self.allow_changing = data.allow_changing
	
		if (data.alt_description) then
			self._altdescription = data.alt_description
			--self.object:set_properties({
			--	infotext = data.alt_description,
			--})
		end
		
		if (data._expoid) then
			self._expoid = data._expoid
			--self.object:set_properties({
			--	_expoid = data._expoid,
			--})
		end
		
		self:update_size()
        self:update_texture()
    end
	
	
    if self.id <0 then
        while expomod.displays[expomod.nextDisplayIndex] ~= nil do
            expomod.nextDisplayIndex = expomod.nextDisplayIndex +1
        end
        self.id = expomod.nextDisplayIndex
        expomod.nextDisplayIndex = expomod.nextDisplayIndex + 1
    end

    expomod.displays[self.id] = self
	--print ("expo on_activate")

end

function DisplayEntity:destroy_correctly()
    --Removed drop as it is bothersome in creative mode
    --minetest.add_item(self.object:get_pos(), expomod.display_item_name)
    expomod.displays[self.id] = nil
    self.object:remove()
end

function DisplayEntity:destroy_correctly_and_cleanup(calling_player)

    --if expomod.insecure_environment then
    --    for key, value in pairs(self.downloaded_textures) do
    --        if expomod.file_exists(expomod.path_to_textures .. value) then
    --            expomod.insecure_environment.os.remove(expomod.path_to_textures .. value)
    --            expomod.msg_player(calling_player, "Removing: " .. value)
    --        end
    --    end
    --end

    --add cleanup
    self:destroy_correctly()
end

function  DisplayEntity:get_staticdata()
    local props = self.object:get_properties ()
	local tmp = ""
	
	if (self._altdescription == "" and props.infotext ~= "") then
			tmp = props.infotext
			self._altdescription =  props.infotext
	else
		tmp = self._altdescription
	end
	
	print ("loading description :" .. self._altdescription)	
	print ("loading description :" .. tmp)	
    return minetest.write_json({
        id = self.id,
        proportions_x = self.proportions_x,
        proportions_y = self.proportions_y,
        size = self.size,
        texture_names = self.texture_names,
        textures_index = self.textures_index,
        textures_count = self.textures_count,
        allow_changing = self.allow_changing,
		alt_description = tmp,
		_expoid = self._expoid,
		
    })
end

function  DisplayEntity:goto_next()
    local index = self.textures_index + 1
    self:goto_number(index)
end

function DisplayEntity:goto_previous()
    local index = self.textures_index - 1
    self:goto_number(index)
end

function DisplayEntity:goto_number(index)
    if index > self.textures_count or index < 0 then
        index = 1
    end
    self.textures_index = index
    self:update_texture()
end

function player_lacks_privilage(player)
     return not minetest.check_player_privs(player, { expopriv=true })
end

function DisplayEntity:on_punch(puncher, time_from_last_punch, tool_capabilities, dir, damage)

    if not self.allow_changing then
		if player_lacks_privilage(puncher) then
            expomod.msg_player(puncher, "Can only change this display with the 'expopriv' privilage.")
            return true
        end
    end

    self:goto_next()
    return true
end

function DisplayEntity:on_rightclick(clicker)
    if player_lacks_privilage(clicker) then
        expomod.msg_player(clicker, "You need the 'expopriv' privilege to edit expomod.displays.")
        return
    end

    self:show_formspec(clicker)
end

function DisplayEntity:show_formspec(clicker)
    local props = self.object:get_properties ()

    local height = 10.5 + self.textures_count*0.5
    
    
    --for k,v in pairs(props) do
    --    print (k)
    --    print (v)
    --end
    --print ("##################### infotext ################")
    --print (props.infotext)	
    --print ("##################### infotext ################")
    

    local testSpec =
    "formspec_version[4]" ..
    "size[12,".. height .."]" ..
    "achor[0,0]"..
    "label[1,0.5; ID: ".. self.id .."]" ..
    "button_exit[5,0.25; 2.5,.5;Destroy;Destroy]"  ..
    "button_exit[7.5,0.25; 4.5,.5;DestroyAndCleanup;Destroy And Cleanup]"  ..
    "tooltip[DestroyAndCleanup; Destroys the display and deletes all the images downloaded through it;#000000;#ffffff]"..
    "label[1,1.25; Move]" ..
    "button[1,1.5; 1,0.5;MoveRight;X+]" ..
    "button[2,1.5; 1,0.5;MoveUp;Y+]" ..
    "button[3,1.5; 1,0.5;MoveForward;Z+]" ..
    "button[1,2; 1,0.5;MoveLeft;X-]" ..
    "button[2,2; 1,0.5;MoveDown;Y-]" ..
    "button[3,2; 1,0.5;MoveBackward;Z-]" ..
    "button[1,2.5; 1,0.5;ScalePlus;Size+]" ..
    "button[2,2.5; 1,0.5;ScaleMinus;Size-]"  ..
    "button[3,2.5; 1,0.5;Rotate;Rotate]" ..

    "label[5,1.25; Proportions]"..
    "button[5,1.5; 1,.5;R1_1;1:1]"  ..
    "button[6,1.5; 1,.5;R16_9;16:9]"  ..
    "button[7,1.5; 1,.5;R4_3;4:3]"  ..
    "button[8,1.5; 1,.5;R5_4;5:4]"  ..
    "field[5,2.5;1,.5;R_CustomX;;".. self.proportions_x .. "]"..
    "field[6,2.5;1,.5;R_CustomY;;".. self.proportions_y .. "]"..
    "button[7,2.5; 2,0.5;R_SetToCustom;Apply Custom]" ..

    "checkbox[1,3.5;AllowChanging;Standard user can select image;".. tostring(self.allow_changing) .."]"..

    "label[1,4.5;URLs:]" ..
    "field[2,4.25;1,.5;Count;Count:;".. self.textures_count .. "]" ..
    "button[5,8.5;2,.5;UpdateImages; Save URLs]" ..
	
	"label[1,5; Description]"..
	"textarea[1,5.5;10,3;ALT_Desc;;"..  self._altdescription .. "]" ..
	
	"button[6,4.5;2,.5;NextModel; Next Model]" 

    local y = 9
    for i = 1, self.textures_count, 1 do
        local default = self.texture_names[i]
        if default == nil then
            default = ""
        end
        testSpec = testSpec .."field[1,".. y ..";10,.5;URL".. i ..";;".. default .."]"
        y = y + 0.5
    end

    minetest.show_formspec(clicker:get_player_name(), expomod.display_formspec_name .. self.id, testSpec)
end


function expomod.handle_display_form(player, formname, fields)
    local id = tonumber(string.sub(formname, expomod.display_formspec_name:len()+1));
    local display = expomod.displays[id]
    if not display then
        expomod.msg_player(player, "Error: no display found with id " .. id)
        return
    end

    if fields.AllowChanging then
    display.allow_changing = tostring(fields.AllowChanging) == "true"
	--print (display.allow_changing)
    end

    if fields.Count then
        local number = tonumber(fields.Count)
        if number then
        display.textures_count = math.min(expomod.display_max_textures, number)
        end
    end

    if fields.ScalePlus then
        display:set_size(math.min(display.size+1, expomod.display_max_size))
    end

    if fields.ScaleMinus then
        display:set_size(math.max(display.size-1, expomod.display_min_size))
    end

    if fields.MoveUp then
        expomod.move_offset(display,0,1,0)
    end

    if fields.MoveDown then
        expomod.move_offset(display, 0,-1,0)
    end

    if fields.MoveRight then
        expomod.move_offset(display,1,0,0)
    end

    if fields.MoveLeft then
        expomod.move_offset(display,-1,0,0)
    end

    if fields.MoveForward then
        expomod.move_offset(display,0,0,1)
    end

    if fields.MoveBackward then
        expomod.move_offset(display,0,0,-1)
    end

    if fields.Rotate then
        local yaw = display.object:get_yaw()
	
        --if yaw == 0 then
        --    display.object:set_yaw(math.pi/2)
        --else
        --    display.object:set_yaw(0)
        --end
		yaw = yaw + (math.pi / 4)
		if yaw > ((math.pi/2) + (math.pi/8)+ (math.pi/4)) then
			yaw = 0
		end
		print ("yaw ".. yaw)
		display.object:set_yaw(yaw)
        display:update_size()
    end

    if fields.R16_9 then
        display:set_proportions(16,9)
    end

    if fields.R4_3 then
        display:set_proportions(4,3)
    end

    if fields.R5_4 then
        display:set_proportions(5,4)
    end

    if fields.R1_1 then
        display:set_proportions(1,1)
    end

    if fields.R_SetToCustom then
        local X = tonumber(fields.R_CustomX)
        local Y = tonumber(fields.R_CustomY)
        if X and Y and Y ~= 0 and X ~= 0 then
            display:set_proportions(X,Y)
        end
    end

    if fields.Destroy then
        display:destroy_correctly()
    end

    if fields.DestroyAndCleanup then
        display:destroy_correctly_and_cleanup(player)
    end
	
    if fields.ALT_Desc then
		--print (fields.ALT_Desc)
		--display.initial_properties.infotext = fields.ALT_Desc
		
		--display.object:set_properties({
		--		infotext = fields.ALT_Desc,
		--})
		
		--display.alt_description = fields.ALT_Desc
		display._altdescription = fields.ALT_Desc
		--local props = display.object:get_properties ()
		--for k,v in pairs(props) do
		--  print (k)
		--   print (v)
		--end
		--print ("##################### infotext ################")
		--print (props.infotext)	
		--print ("##################### infotext ################")
		local player_name = player:get_player_name()

		-- Get the dig and place count from storage, or default to 0
		local meta        = player:get_meta()
		meta:set_string("expo:description", fields.ALT_Desc)
		expomod.update_text (player, fields.ALT_Desc)

    end
	if fields.NextModel then
		local gids = expomod.saved_ghuds[player:get_player_name()]
	
		if gids then
			if (expomod.gameui.book[expomod.gameui.model]) then
				expomod.gameui.book[expomod.gameui.model].remove_hud(player, gids)
			else
				print ("EXPO : FRAME OBJECT = nil !!!!!!!!")
			end
			expomod.saved_ghuds[player:get_player_name()] = nil
			expomod.gameui.model = expomod.gameui.model + 1
			if (expomod.gameui.model > 4) then
				expomod.gameui.model = 0
			end	
			expomod.create_hud(player)
			expomod.modstorage:set_int("expo_model", expomod.gameui.model)
		end
	end
    
	if fields.UpdateImages then
        local newTextures = {}
        for i = 1, display.textures_count, 1 do
            local current = "URL"..i;
            local url = fields[current]
            newTextures[i] = "default.jpg"

            if url and url ~= "" then
                local valid = expomod.ends_with_one_of(url, {".jpg", ".jpeg", ".JPG", ".png", ".PNG"})
                local fixSpelling = expomod.ends_with_one_of(url, {".JPG", ".PNG"})
                print ("testing image url")
                print ("url valid")
                if valid then
                    local name = url:match( "([^/]+)$")
                    if fixSpelling then
                        name = name:gsub(".JPG", ".jpg")
                        name = name:gsub(".PNG", ".png")
                    end
                    print ("file name " .. name)
                    print ("file path " .. expomod.path_to_textures .. " file name:" .. name)
                    if expomod.file_exists(expomod.path_to_textures .. url) then
                        newTextures[i] = url
                        print (url)
                        print (i)
                        --expomod.msg_player(player, "Image " .. i .. " already downloaded.")
                        --expomod.msg_player(player, "Image " .. url .. " loaded.")
                        expomod.msg_player(player, "Image " .. name .. url .." loaded.")
                    --else
                    --    local ok = download_and_save_texture(player, url, name)
                    --    if ok then
                    --        newTextures[i] = name
                    --        table.insert(display.downloaded_textures,name)
                    --    else
                    --        --error
                    --    end
                    end
                else
                    expomod.msg_player(player, "Only .png and .jpg are supported. Invalid URL: " .. i .. " -> " .. url)
                end
            end
        end

        display:change_textures_to(newTextures)
    end
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if expomod.starts_with(formname, expomod.display_formspec_name) then
        expomod.handle_display_form(player, formname, fields)
    elseif expomod.starts_with(formname, expomod.display_remote_item_formspec_name) then
        expomod.handle_display_remote_form(player, formname, fields)
    end
end)

function expomod.move_offset (display, x, y, z)
    local pos = display.object:get_pos()
    pos.x = pos.x + x
    pos.y = pos.y + y
    pos.z = pos.z + z
    display.object:move_to(pos);
end


 function expomod.starts_with(str, start)
    return str:sub(1, #start) == start
 end

 function expomod.ends_with(str, ending)
    return ending == "" or str:sub(-#ending) == ending
 end

 function expomod.ends_with_one_of(str, endings)
    if str == "" then
        return true
    end

    for index, value in ipairs(endings) do
        if str:sub(-#value) == value then
            return true
        end
    end
    return false
 end

 function expomod.msg_player(player, msg)
     minetest.chat_send_player(player:get_player_name(), msg)
 end

 function expomod.file_exists(name)
    local f=io.open(name,"r")
    if f~=nil then io.close(f) return true else return false end
 end



minetest.register_entity(expomod.display_entity_name, DisplayEntity)



minetest.register_craftitem(expomod.display_item_name,{
    description = "Expo Display",
    inventory_image = "display_item.png",
    on_place = function(itemstack, user, pointed_thing)

        if pointed_thing.type == "node" then
        minetest.add_entity(pointed_thing.above,  expomod.display_entity_name)

        --expomod.displays are not consumed as this is meant as a creative mode only tool
        --itemstack:take_item()
        end
        return itemstack
    end
})


minetest.register_craftitem(expomod.display_remote_item_name, {
    description = "Expo Display Remote",
    inventory_image = "display_remote_item.png",
    on_use = function (itemstack, user, pointed_thing)
        local meta = itemstack:get_meta()

    if pointed_thing then
        if pointed_thing.type == "object" then

            if pointed_thing.ref then
            if pointed_thing.ref.get_luaentity then
                local entity = pointed_thing.ref:get_luaentity()
                if entity then
                    meta:set_int("display_id", entity.id)
                    expomod.msg_player(user, "[Display Remote] Bound to display with ID " .. entity.id)
                    return itemstack
                end
        end
        end
        end

        local id = meta:get_int("display_id")
        if id >= 0 and expomod.displays[id] ~= nil then
            minetest.show_formspec(user:get_player_name(), expomod.display_remote_item_formspec_name .. id, expomod.get_remote_formspec(id))
        end
    end

        return itemstack
    end

})

function expomod.get_remote_formspec(id)

    local formspec = ""

    if id < 0 or expomod.displays[id] == nil then
       formspec = "formspec_version[4]" ..
       "size[5,5]" ..
       "achor[0,0]" ..
    "label[1,1; Bound to no display, leftclick on a display to connect]"
    else
        local display = expomod.displays[id]
        local sizeY = 5.5 + math.floor(display.textures_count/5) * 0.5

        formspec = "formspec_version[4]" ..
        "size[5,".. sizeY .."]" ..
        "achor[0,0]" ..
        "label[1,1; Bound to display #".. id.." ] " ..
        "label[1,2; Currently: " .. display.textures_index .. "/" .. display.textures_count .."]" ..
        "button[1,3;1,1;Left;<-]" ..
        "button[3,3;1,1;Right;->]"

        for i = 1, display.textures_count, 1 do
            local igrid = i-1
            local x = (igrid % 5)
            local y = 4.5 + math.floor(igrid/5) * 0.5
            formspec = formspec ..
            "button["..x .. "," .. y .. ";1,.5;goto_" .. i .. ";" .. i .. "]"
        end

        --current slide, next / previous buttons
        -- buttons for each slide
    end
    return formspec
end

function expomod.handle_display_remote_form(player, formname, fields)
    local id = tonumber(string.sub(formname, expomod.display_remote_item_formspec_name:len()+1))
    --expomod.msg_player(player, "Received form ID:" .. id)
    local display = expomod.displays[id]

    if display then
        if fields.Right then
            expomod.msg_player(player, "Pressed right")
            display:goto_next()


        elseif fields.Left then
            display:goto_previous()
            expomod.msg_player(player, "Pressed left")

        else

            for i = 1, display.textures_count, 1 do
                if fields["goto_"..i] then
                    display:goto_number(i)
                    expomod.msg_player(player,"pressed " ..i)
                    return
                end
            end

        end
    else
        expomod.msg_player(player, "no display with ID:" .. id)
    end
end

minetest.register_chatcommand("log_expo_textures", {
    privs = {
        expopriv = true,
    },
    func = function(name, param)
        if not expomod.insecure_environment then
        return false
        end

        local msg = "TEXTURES:"
        msg = msg.. "NOT IMPLEMENTED YET"
        return true, msg
    end
})

--########################## HUD element


--local saved_huds = {}
expomod.saved_ghuds = {}
expomod.default_background = "background.png"
expomod.visible = false


expomod_gamedisplay_tablet = {}
function expomod_gamedisplay_tablet.create_hud(player)
local player_name = player:get_player_name()
    --local ids = saved_huds[player_name]
	local gids = expomod.saved_ghuds[player_name]
	
    if not gids then
		print ("expo : registering hud")
        --ids = {}
		gids = {}
        --saved_huds[player_name] = gids
		expomod.saved_ghuds[player_name]= gids
		local ghid = player:hud_add({
			hud_elem_type = "image",
			position  = {x = 1, y = 0.5},
			alignment = {x=1, y=1},
			offset    = {x = 0, y = 0},
			scale     = { x = -50, y = -50},
			text = "background.png"
		})
		gids["background"] = ghid
		local ghid2 = player:hud_add({
			hud_elem_type = "image",
			position  = {x = 1, y = 0.5},
			alignment = {x=1, y=1},
			offset    = {x = -32, y = -32},
			scale     = { x = 1, y = 1},
			text = "bordure_up.png"
		})
		gids["bordure_up"] = ghid2
		local ghid3 = player:hud_add({
			hud_elem_type = "image",
			position  = {x = 1, y = 0.5},
			alignment = {x=1, y=1},
			offset    = {x = -32, y = 0},
			scale     = { x = 1, y = 1},
			text = "bordure_left.png"
		})
		gids["bordure_left"] = ghid3
		local hid = player:hud_add({
			hud_elem_type = "text",
			position  = {x = 1, y = 0.5},
			offset    = {x = 8, y = 8},
			text      = "Text à la con un peu plus long \npour tester la limite de ce putain d'écran débile",
			alignment = {x=1, y=1},
			scale     = { x = -100, y = -100},
			number    = 0x000000,
			size = {x=1.5,y=0,z=0},
		})
		gids["description"]= hid
		
		
		gids.position = 1
		gids.speed = 0.05
		gids.endposition = 0.75
		gids.visible = false
        
    end
end
function expomod_gamedisplay_tablet.anim_update_position (player, gids, position)
	local back_position = {x=position, y = 0.5}
	
	player:hud_change(gids["description"], "position", back_position)
	player:hud_change(gids["background"], "position", back_position)
	player:hud_change(gids["bordure_up"], "position", back_position)
	player:hud_change(gids["bordure_left"], "position", back_position)
end

function expomod_gamedisplay_tablet.remove_hud (player, gids)
	local back_position = {x=position, y = 0.5}
	
	player:hud_remove(gids["description"])
	player:hud_remove(gids["background"])
	player:hud_remove(gids["bordure_up"])
	player:hud_remove(gids["bordure_left"])
	
end

expomod_gamedisplay_frame1 = {}
function expomod_gamedisplay_frame1.create_hud(player)
local player_name = player:get_player_name()
    --local ids = saved_huds[player_name]
	local gids = expomod.saved_ghuds[player_name]
	
    if not gids then
		print ("expo : registering hud")
        --ids = {}
		gids = {}
        --saved_huds[player_name] = gids
		expomod.saved_ghuds[player_name]= gids
		local ghid = player:hud_add({
			hud_elem_type = "image",
			position  = {x = 1, y = 0.25},
			alignment = {x=1, y=1},
			offset    = {x = -32, y = -32},
			scale     = { x = 1, y = 1},
			text = "1530893769.png"
		})
		gids["background"] = ghid
				
		local hid = player:hud_add({
			hud_elem_type = "text",
			position  = {x = 1, y = 0.25},
			offset    = {x = 166 -32, y = 166-32},
			text      = "Text à la con un peu plus long \npour tester la limite de ce putain d'écran débile",
			alignment = {x=1, y=1},
			scale     = { x = -100, y = -100},
			number    = 0x000000,
			size = {x=1.5,y=0,z=0},
		})
		gids["description"]= hid
		
		
		gids.position = 1
		gids.speed = 0.05
		gids.endposition = 0.75
		gids.visible = false
        
    end
end

function expomod_gamedisplay_frame1.anim_update_position (player, gids, position)
	local back_position = {x=position, y = 0.5}
	
	player:hud_change(gids["description"], "position", back_position)
	player:hud_change(gids["background"], "position", back_position)
	
end

function expomod_gamedisplay_frame1.remove_hud (player, gids)
	local back_position = {x=position, y = 0.5}
	
	player:hud_remove(gids["description"])
	player:hud_remove(gids["background"])
	
end

expomod_gamedisplay_frame2 = {}
function expomod_gamedisplay_frame2.create_hud(player)
local player_name = player:get_player_name()
    --local ids = saved_huds[player_name]
	local gids = expomod.saved_ghuds[player_name]
	
    if not gids then
		print ("expo : registering hud")
        --ids = {}
		gids = {}
        --saved_huds[player_name] = gids
		expomod.saved_ghuds[player_name]= gids
		local ghid = player:hud_add({
			hud_elem_type = "image",
			position  = {x = 1, y = 0.25},
			alignment = {x=1, y=1},
			offset    = {x = -32, y = -32},
			scale     = { x = 1, y = 1},
			text = "1370290172.png"
		})
		gids["background"] = ghid
				
		local hid = player:hud_add({
			hud_elem_type = "text",
			position  = {x = 1, y = 0.25},
			offset    = {x = 85 -32, y = 122-32},
			text      = "Text à la con un peu plus long \npour tester la limite de ce putain d'écran débile",
			alignment = {x=1, y=1},
			scale     = { x = -100, y = -100},
			number    = 0xffffff,
			size = {x=1.5,y=0,z=0},
		})
		gids["description"]= hid
		
		
		gids.position = 1
		gids.speed = 0.05
		gids.endposition = 0.75
		gids.visible = false
        
    end
end

function expomod_gamedisplay_frame2.anim_update_position (player, gids, position)
	local back_position = {x=position, y = 0.5}
	
	player:hud_change(gids["description"], "position", back_position)
	player:hud_change(gids["background"], "position", back_position)
	
end

function expomod_gamedisplay_frame2.remove_hud (player, gids)
	local back_position = {x=position, y = 0.5}
	
	player:hud_remove(gids["description"])
	player:hud_remove(gids["background"])
	
end



expomod_gamedisplay_frame3 = {}
function expomod_gamedisplay_frame3.create_hud(player)
local player_name = player:get_player_name()
    --local ids = saved_huds[player_name]
	local gids = expomod.saved_ghuds[player_name]
	
    if not gids then
		print ("expo : registering hud")
        --ids = {}
		gids = {}
        --saved_huds[player_name] = gids
		expomod.saved_ghuds[player_name]= gids
		local ghid = player:hud_add({
			hud_elem_type = "image",
			position  = {x = 1, y = 0.25},
			alignment = {x=1, y=1},
			offset    = {x = -19, y = -214},
			scale     = { x = 1, y = 1},
			text = "nodrugs.png"
		})
		gids["background"] = ghid
				
		local hid = player:hud_add({
			hud_elem_type = "text",
			position  = {x = 1, y = 0.25},
			offset    = {x = 8, y = 8},
			text      = "Text à la con un peu plus long \npour tester la limite de ce putain d'écran débile",
			alignment = {x=1, y=1},
			scale     = { x = -100, y = -100},
			number    = 0xffffff,
			size = {x=1.5,y=0,z=0},
		})
		gids["description"]= hid
		
		
		gids.position = 1
		gids.speed = 0.05
		gids.endposition = 0.75
		gids.visible = false
        
    end
end
function expomod_gamedisplay_frame3.anim_update_position (player, gids, position)
	local back_position = {x=position, y = 0.5}
	
	player:hud_change(gids["description"], "position", back_position)
	player:hud_change(gids["background"], "position", back_position)
	
end

function expomod_gamedisplay_frame3.remove_hud (player, gids)
	local back_position = {x=position, y = 0.5}
	
	player:hud_remove(gids["description"])
	player:hud_remove(gids["background"])
	
end


expomod_gamedisplay_frame4 = {}
function expomod_gamedisplay_frame4.create_hud(player)
local player_name = player:get_player_name()
    --local ids = saved_huds[player_name]
	local gids = expomod.saved_ghuds[player_name]
	
    if not gids then
		print ("expo : registering hud")
        --ids = {}
		gids = {}
        --saved_huds[player_name] = gids
		expomod.saved_ghuds[player_name]= gids
		local ghid = player:hud_add({
			hud_elem_type = "image",
			position  = {x = 1, y = 0.25},
			alignment = {x=1, y=1},
			offset    = {x = -32, y = -32},
			scale     = { x = 1, y = 1},
			text = "telegrampaper.png"
		})
		gids["background"] = ghid
				
		local hid = player:hud_add({
			hud_elem_type = "text",
			position  = {x = 1, y = 0.25},
			offset    = {x = 77-32, y = 204-32},
			text      = "Text à la con un peu plus long \npour tester la limite de ce putain d'écran débile",
			alignment = {x=1, y=1},
			scale     = { x = -100, y = -100},
			number    = 0x101010,
			size = {x=1.5,y=0,z=0},
		})
		gids["description"]= hid
		
		
		gids.position = 1
		gids.speed = 0.05
		gids.endposition = 0.75
		gids.visible = false
        
    end
end
function expomod_gamedisplay_frame4.anim_update_position (player, gids, position)
	local back_position = {x=position, y = 0.5}
	
	player:hud_change(gids["description"], "position", back_position)
	player:hud_change(gids["background"], "position", back_position)
	
end

function expomod_gamedisplay_frame4.remove_hud (player, gids)
	local back_position = {x=position, y = 0.5}
	
	player:hud_remove(gids["description"])
	player:hud_remove(gids["background"])
	
end



expomod.gameui.book = {}
expomod.gameui.book[0]= expomod_gamedisplay_tablet
expomod.gameui.book[1]= expomod_gamedisplay_frame1
expomod.gameui.book[2]= expomod_gamedisplay_frame2
expomod.gameui.book[3]= expomod_gamedisplay_frame3
expomod.gameui.book[4]= expomod_gamedisplay_frame4

function expomod.update_visible (player, visible)
	local player_name = player:get_player_name()
	local gids = expomod.saved_ghuds[player_name]
	if gids then     
		gids.visible = visible	
	end
end



function expomod.update_text (player, text, visible)
	local player_name = player:get_player_name()
	local gids = expomod.saved_ghuds[player_name]
	if gids then
        player:hud_change(gids["description"], "text", text)
		--player:hud_change(gids["background"], "text", expomod.default_background)
		gids.visible = visible	
		
	end
	
end

	
function expomod.create_hud(player)
	if (expomod.gameui.book[expomod.gameui.model]) then
		expomod.gameui.book[expomod.gameui.model].create_hud(player)
	else
		print ("EXPO : FRAME OBJECT = nil !!!!!!!!")
	end
    
end

function expomod.get_looking_entity(player) -- Return the node the given player is looking at or nil
    local lookat
	local found_display = false
	local player_look_vector = vector.multiply(player:get_look_dir(), 24)
	
	--print ("### RAYCAST ###")
	local startpos = vector.add (player:get_pos(), {x=0,y=1.65,z=0})
	local raycast = minetest.raycast(startpos, vector.add(player:get_pos(), player_look_vector), true, false)
	for pointed_thing in raycast do
		--print (pointed_thing.type)
		if pointed_thing.type == "object" then
			if pointed_thing then
				--[[
				for k,v in pairs(pointed_thing) do
					print ("key: " .. k)
					print (v)
				end
				print ("### get object properties")
				local props = pointed_thing.ref:get_properties ()
				print (props)
				for k1,v1 in pairs (props) do
					print ("--key: " ..k1)
					print (v1)
				end
				--]]
					
							
				--print ("### entity ")
				if pointed_thing.ref then
					if pointed_thing.ref.get_luaentity then
						local entity = pointed_thing.ref:get_luaentity()
						if entity then
							--print (entity)
							--for k1, v1 in pairs (entity) do
							--	print ("entitykey :" .. k1)
							--	print (v1)
							--end
							
							if entity._expoid then
								if entity._expoid == "expodisplay" then
									
									
									if entity._altdescription and entity._altdescription ~= "" then
										
										--print ("description:" .. entity._altdescription)
										expomod.update_text (player, entity._altdescription, true)
										found_display = true
										break
									end	
								end
							end
							
						end
						
					end
				end
				
			end
			
		end
    end
	if not found_display then
		expomod.update_visible (player, false)
	end
	--print ("### END RAYCAST ###")
	return lookat
	
end

function expomod.check_entities ()
	for pid, player in ipairs(minetest:get_connected_players()) do
		expomod.get_looking_entity(player)
	end
end	

function expomod.anim_update_position (player, gids, position)
	if (expomod.gameui.book[expomod.gameui.model] and expomod.gameui.book[expomod.gameui.model].anim_update_position) then
		expomod.gameui.book[expomod.gameui.model].anim_update_position (player, gids, position)
	else
		print ("EXPO : FRAME OBJECT = nil !!!!!!!!")
	end
    
end

function expomod.anim_display (player)
	local player_name = player:get_player_name()
    local gids = expomod.saved_ghuds[player_name]
	
	if gids.visible then
		if gids.position > gids.endposition then
			gids.position = gids.position - gids.speed
			if gids.position < gids.endposition then
				gids.position = gids.endposition
			end
			expomod.anim_update_position (player, gids, gids.position)	
		end
	else
		if gids.position < 1.1 then
			gids.position = gids.position + gids.speed
			if gids.position > 1.1 then
				gids.position = 1.1
			end
			expomod.anim_update_position (player, gids, gids.position)	
		end
	end	
end

function expomod.anim_player_displays ()
	for pid, player in ipairs(minetest:get_connected_players()) do
		expomod.anim_display (player)
	end
end
	
print ("# Expo: registering player join")
minetest.register_on_joinplayer(expomod.create_hud)

minetest.register_on_leaveplayer(function(player)
    expomod.saved_ghuds[player:get_player_name()] = nil
end)

print ("# Expo: registering globalstep")
expomod.timer = 0
expomod.animtimer = 0
minetest.register_globalstep(function(dtime)
	expomod.timer = expomod.timer + dtime;
	expomod.animtimer = expomod.animtimer + dtime;
	if expomod.timer >= 0.25 then
		
		expomod.timer = 0
		expomod.check_entities ()
	end
	if expomod.animtimer >= 0.1 then
		expomod.animtimer = 0
		expomod.anim_player_displays ()
	end
	
end)

print ("# Expo MOD NAME " .. expomod.modname)
print ("# Expo MOD expomod.display_item_name " .. expomod.display_item_name)
print ("# Expo MOD expomod.display_entity_name " .. expomod.display_entity_name)
print("# Expo [OK]")
print ('###############################################')