local pui = require("neverlose/pui")
local ffi = require("ffi")
local menu = {
    main = pui.create("", "\n", 1),
    Hit_ = pui.create("", "\n\n", 2),
    Scope_ = pui.create("", "\n\n\n", 2),
    ref = {},
    Gui = {
        Hit = {},
        Scope = {},
    },
    callback = {
        render = {},
        createmove = {},
        override_view = {},
        shutdown = {},
    }
}

menu.list = menu.main:list("", "Visuals","asd")

menu.Gui = {
    Hit = {
        enabled = menu.Hit_:switch("Damage indicator", false),
        combobox = menu.Hit_:combo("Font", { "Default", "Small", "Console", "Bold" }),
        color = menu.Hit_:color_picker("Color\n\n", color(255,255,255)),
        anim = menu.Hit_:switch("Transition animation", true),
    },
    Scope = {
        enabled = menu.Scope_:switch("Custom scope", false),
        color = menu.Scope_:color_picker("Color\n", {
            ["Default"] = {
                color(255, 255, 255, 255),
            },
            ["Gradient"] = {
                color(255, 255, 255, 255), color(0, 0, 0, 255),
            },
        }),
        options = menu.Scope_:selectable("options",'Dynamic offset', 'Remove top line', 'Disable animation'),
        size = menu.Scope_:slider("lines initial pos", 0, 500, 190);
        offset = menu.Scope_:slider("lines offset", 0, 500, 10);
        thickness = menu.Scope_:slider("lines thickness", 1, 10, 1, 1, 'px');
        fade = menu.Scope_:slider("Anim speed", 3, 20, 12, 1, function(v)
            return v == 3 and "Off" or (v .. " fr")
        end)
    },
}
menu.ref = {
    Aimbot_Ragebot_Main = ui.find("Aimbot", "Ragebot", "Main");
    visuals_World_Main = ui.find("Visuals", "World", "Main");
    Visuals_World_Other = ui.find("Visuals", "World", "Other");
    Thirdperson   = ui.find("Visuals", "World", "Main", "Force Thirdperson");
    Visuals_World_Main_Override_Zoom_Scope_Overlay = ui.find("Visuals", "World", "Main", "Override Zoom", "Scope Overlay");
}

local function Set_visibility_callback()
    local Hit_enabled = menu.list:get() == 1 and menu.Gui.Hit.enabled:get()
    local Scope_enabled = menu.list:get() == 1 and menu.Gui.Scope.enabled:get()
    menu.Gui.Hit.enabled:set_visible(menu.list:get() == 1)
    menu.Gui.Hit.combobox:set_visible(Hit_enabled)
    menu.Gui.Hit.color:set_visible(Hit_enabled)
    menu.Gui.Hit.anim:set_visible(Hit_enabled)

    menu.Gui.Scope.enabled:set_visible(menu.list:get() == 1)
    menu.Gui.Scope.color:visibility(Scope_enabled)
    menu.Gui.Scope.options:visibility(Scope_enabled)
    menu.Gui.Scope.size:visibility(Scope_enabled)
    menu.Gui.Scope.offset:visibility(Scope_enabled)
    menu.Gui.Scope.thickness:visibility(Scope_enabled)
    menu.Gui.Scope.fade:visibility(Scope_enabled)
end

local Scope_Overlay = menu.ref.Visuals_World_Main_Override_Zoom_Scope_Overlay
local def = Scope_Overlay:get()

local Function = {
    Camera_Animation = function ()
        local gradient_text = function (r1, g1, b1, a1, r2, g2, b2, a2, text) local output = '' local len = #text-1 local rinc = (r2 - r1) / len local ginc = (g2 - g1) / len local binc = (b2 - b1) / len local ainc = (a2 - a1) / len for i=1, len+1 do output = output .. ('\a%02x%02x%02x%02x%s'):format(r1, g1, b1, a1, text:sub(i, i)) r1 = r1 + rinc g1 = g1 + ginc b1 = b1 + binc a1 = a1 + ainc end return output end;
        
        local enabled = menu.ref.Visuals_World_Other:switch("Camera Animation", false);
        local sub = enabled:create();
        local Camera_Changer = sub:combo(gradient_text(50,245,215,255,75,85,240,255,"Camera Animation"), { "Disable", "Bob", "Collision", "Follow Bone", "Static" });
        local Camera_Z       = sub:slider("Camera Height", -20, 50, 0);
        
        local ducking       = false;
        local last_z        = 0;
        local on_land_tick  = 0;
        local bunnyhop_tick = 0;
        menu.callback.createmove.callback_on_createmove = function(cmd)
            local bit = require("bit")
            ducking = bit.band(cmd.buttons, bit.lshift(1, 2)) ~= 0
        end
        menu.callback.render.callback_on_render = function()
            Camera_Z:visibility(Camera_Changer:get() ~= "Disable")
        end
        menu.callback.override_view.callback_on_view = function(view)
            if enabled:get() == false then return end
            if math.abs(view.camera.z - last_z) > 80 then last_z = view.camera.z end
        
            if Camera_Changer:get() == "Bob" and menu.ref.Thirdperson:get() then
                local me = entity.get_local_player()
                if not me:is_alive() then return end
                local on_land  = me["m_vecVelocity[2]"] == 0
                local bone_z   = view.camera.z
                local camera_z = Camera_Z:get()
            
                if on_land then
                    on_land_tick = on_land_tick + 1
                else
                    on_land_tick = 0
                end
            
                if on_land_tick < 10 and on_land_tick ~= 0 then
                    bunnyhop_tick = 80
                end
            
                if bunnyhop_tick > 0 and last_z < bone_z then
                    bunnyhop_tick = bunnyhop_tick - 1
                    last_z = last_z + 1
                else
                    if bunnyhop_tick > 0 then bunnyhop_tick = bunnyhop_tick - 10 end
                    last_z = bone_z
                end
            
                view.camera.z = last_z + camera_z
            
            elseif Camera_Changer:get() == "Collision" and menu.ref.Thirdperson:get() then
                local me = entity.get_local_player()
                if not me:is_alive() then return end
                local speed    = me["m_vecVelocity[2]"]
                local camera_z = Camera_Z:get()
            
                if speed > 80 then
                    last_z = view.camera.z + (ducking and 18 or 12)
                elseif speed < -80 then
                    last_z = view.camera.z - (ducking and 18 or 12)
                else
                    last_z = view.camera.z
                end
            
                view.camera.z = last_z + camera_z
            
            elseif Camera_Changer:get() == "Follow Bone" and menu.ref.Thirdperson:get() then
                local me = entity.get_local_player()
                if not me:is_alive() then return end
                local bone_z   = me:get_bone_position(8).z
                local camera_z = Camera_Z:get()
            
                view.camera.z = bone_z + camera_z
            
            elseif Camera_Changer:get() == "Static" and menu.ref.Thirdperson:get() then
                if math.abs(view.camera.z - last_z) > 80 then last_z = view.camera.z end
                local camera_z = Camera_Z:get()
            
                if last_z > view.camera.z + camera_z + 5 then
                    last_z = last_z - 1
                elseif last_z < view.camera.z + camera_z - 25 then
                    last_z = last_z + 1
                end
            
                view.camera.z = last_z
            end
        end
    end;
    Aspect_Ratio = function ()
        local aspect_ratio = menu.ref.visuals_World_Main:switch("纵横比", false)
        local sub = aspect_ratio:create()
        local slider = sub:slider("value", 0, 250, 0, 0.01, function(v) return v == 0 and "Auto" or "" end)
        local function update() if aspect_ratio:get() then local v = slider:get() cvar.r_aspectratio:float(v == 0 and 0 or v / 100, true) else cvar.r_aspectratio:float(0, true) end end
        aspect_ratio:set_callback(update)
        slider:set_callback(update)
        update()
    end;
    AX = function ()
        local ax_switch = menu.ref.Aimbot_Ragebot_Main:switch("\af5fd8effAX (Anti Defensive)", true)
        local function anti_ax()
            cvar["cl_lagcompensation"]:int(ax_switch:get() and 0 or 1)
        end
        ax_switch:set_callback(anti_ax)
    end;
    Damage_indicator = function ()
        -- 武器定义索引 → 菜单名称映射
        local weapon_to_menu = {
            -- Pistols
            [61] = "Pistols",  -- USP-S
            [4]  = "Pistols",  -- Glock-18
            [3]  = "Pistols",  -- Five-SeveN
            [30] = "Pistols",  -- Tec-9
            [2]  = "Pistols",  -- Dual Berettas
            [32] = "Pistols",  -- P2000
            [36] = "Pistols",  -- P250
            [63] = "Pistols",  -- CZ75-Auto
            -- Deagle
            [1]  = "Desert Eagle",
            -- R8
            [64] = "R8 Revolver",
            -- SSG-08
            [40] = "SSG-08",
            -- AWP
            [9]  = "AWP",
            -- AK-47
            [7]  = "AK-47",
            -- M4A4 / M4A1-S
            [16] = "M4A1/M4A4",
            [60] = "M4A1/M4A4",
            -- AUG / SG 553
            [39] = "AUG/SG 553",
            [8]  = "AUG/SG 553",
            -- AutoSnipers
            [11] = "AutoSnipers",
            [38] = "AutoSnipers",
            -- Shotguns
            [25] = "Shotguns",
            [27] = "Shotguns",
            [29] = "Shotguns",
            [35] = "Shotguns",
            -- SMGs
            [17] = "SMGs",
            [19] = "SMGs",
            [23] = "SMGs",
            [24] = "SMGs",
            [26] = "SMGs",
            [33] = "SMGs",
            -- Rifles (Famas, Galil 等杂项步枪)
            [10] = "Rifles",
            [13] = "Rifles",
            -- Snipers (Scout 等杂项狙击)
            [34] = "Snipers",
            -- Machineguns
            [14] = "Machineguns",
            [28] = "Machineguns",
            -- Taser
            [31] = "Taser",
        }
        -- 获取当前手上武器
        local function get_active_weapon()
            local local_player = entity.get_local_player()
            if local_player == nil then
                return nil
            end
            return local_player:get_player_weapon()
        end
        -- 获取当前武器在菜单中的名称，未匹配返回 "Global"
        local function get_weapon_menu_name()
            local wep = get_active_weapon()
            if wep == nil then
                return "Global"
            end
            return weapon_to_menu[wep:get_weapon_index()] or "Global"
        end
        -- 获取当前武器对应的 "Min. Damage" 配置值 (Pistols 取 "Hit Chance")
        local function get_config_for_current_weapon()
            local menu_name = get_weapon_menu_name()
            local ok, Damage = pcall(ui.find, "Aimbot", "Ragebot", "Selection", menu_name, "Min. Damage")
            if not ok or Damage == nil then
                return nil
            end
            return Damage:get()
        end
        -- 平滑插值：a 平滑过渡到 b，s 控制速度（越大越快）
        local function lerp(a, b, s)
            local frame_time = globals.frametime
            if frame_time == 0 then return a end
            local c = a + (b - a) * frame_time * (s or 8)
            return math.abs(b - c) < 0.005 and b or c
        end
        -- 显隐过渡：should_be_active 为 true 时从 0 渐变到 1，false 时从 1 渐变到 0
        local function condition(current_val, should_be_active, speed)
            local frame_time = globals.frametime
            if frame_time == 0 then return current_val end
            local new_val = current_val + (frame_time * math.abs(speed) * (should_be_active and 1 or -1))
            return math.max(0, math.min(1, new_val))
        end
        
        -- 动画状态
        local anim = {dmg = 0, progress = 0}
        menu.callback.render.DrawHitNumber = function ()
            if not menu.Gui.Hit.enabled:get() then return end
            if not entity.get_local_player() or not entity.get_local_player():is_alive() then return end
            -- 更新动画状态
            local target_dmg = get_config_for_current_weapon() or 0
            local is_visible = menu.Gui.Hit.enabled:get()
            if menu.Gui.Hit.anim:get() then
                anim.progress = condition(anim.progress, is_visible, 8)
                anim.dmg = lerp(anim.dmg, target_dmg, 16)
            else
                anim.progress = is_visible and 1 or 0
                anim.dmg = target_dmg
            end
        
            if anim.progress <= 0.005 then return end
        
            -- 计算文字（和原版逻辑一致：0→"A", >100→"+xx"）
            local dmg_val = math.floor(anim.dmg + 0.5)
            local dmg_text = dmg_val == 0 and "A" or dmg_val > 100 and ("+" .. (dmg_val - 100)) or tostring(dmg_val)
        
            local x, y = render.screen_size().x / 2, render.screen_size().y / 2
            local font_type = menu.Gui.Hit.combobox:get()
            local font = 0
            local offset_x, offset_y = 3, 0
        
            if font_type == "Default" then
                font = 0
            elseif font_type == "Small" then
                font = 2
                offset_x, offset_y = 1, 1
            elseif font_type == "Console" then
                font = 1
            elseif font_type == "Bold" then
                font = 3
                offset_x = 0
            end
        
            local size = render.measure_text(font, nil, dmg_text)
            local pos = vector(x + offset_x, y - size.y + offset_y)
        
            -- alpha 随 progress 变化，带 ovr_alpha 风格（可后续接 override 检测）
            local final_alpha = math.floor((96 + 159 * 1) * anim.progress)
            local hit_color = menu.Gui.Hit.color:get()
            render.text(font, pos, color(hit_color.r, hit_color.g, hit_color.b, final_alpha), nil, dmg_text)
        end
    end;
    batter_scope = function ()
        local function vtable_thunk(index, typestring)
            local t = ffi.typeof(typestring)
            return function(instance, ...)
                if instance then
                    return ffi.cast(t, (ffi.cast("void***", instance)[0])[index])(instance, ...)
                end
            end
        end

        local native_getClientEntity = utils.get_vfunc("client.dll", "VClientEntityList003", 3, "void*(__thiscall*)(void*, int)")
        local native_getSpread = vtable_thunk(453, "float(__thiscall*)(void*)")
        local native_getInaccuracy = vtable_thunk(483, "float(__thiscall*)(void*)")

        local progress = 0
        menu.callback.render.DrawCrosshairs = function ()
            if not menu.Gui.Scope.enabled:get() then return end
            -- 强制移除原版狙击镜遮罩
            if Scope_Overlay:get() ~= "Remove All" then
                Scope_Overlay:set("Remove All")
            end
            local lp = entity.get_local_player()
            if not lp or not lp:is_alive() then return end
            local should_show = lp.m_bIsScoped and not lp.m_bResumeZoom
        
            -- 动画
            local speed = menu.Gui.Scope.fade:get()
            local options = menu.Gui.Scope.options:get()
            local has = function(name)
                for _, v in ipairs(options) do
                    if v == name then return true end
                end
                return false
            end
            local is_disable_anim = has("Disable animation")
            local ft = speed > 3 and globals.frametime * speed or 1
            if speed == 3 or is_disable_anim then
                progress = should_show and 1 or 0
            else
                progress = math.max(0, math.min(1, progress + (should_show and ft or -ft)))
            end
        
            if progress <= 0.005 then return end
        
            local ss = render.screen_size()
            local hw = math.floor(ss.x * 0.5) + 1
            local hh = math.floor(ss.y * 0.5) + 1
            local scale = ss.y / 1080
        
            local size = menu.Gui.Scope.size:get() * scale
            local offset = menu.Gui.Scope.offset:get() * scale
            local thickness = menu.Gui.Scope.thickness:get()
        
            -- 动态偏移：跟随 spread + inaccuracy
            local dynamic_mod = 0
            if has("Dynamic offset") then
                local wpn = lp:get_player_weapon()
                if wpn then
                    local ok, ent = pcall(native_getClientEntity, wpn:get_index())
                    if ok and ent ~= nil then
                        local spread = native_getSpread(ent) or 0
                        local inaccuracy = native_getInaccuracy(ent) or 0
                        dynamic_mod = (inaccuracy + spread) * 360
                    end
                end
            end
            size = size + dynamic_mod
            offset = offset + dynamic_mod
        
            -- 位置动画：线条从 offset 滑动到 size
            if not is_disable_anim then
                size = offset + (size - offset) * progress
            end
        
            if size <= offset + 0.5 then return end
        
            local mode, colors = menu.Gui.Scope.color:get()
            local color1, color2
            if type(colors) == "table" then
                color1 = colors[1]
                color2 = colors[2] or colors[1]
            else
                color1, color2 = colors, colors
            end
            if not color1 then color1 = color(255, 255, 255) end
            if not color2 then color2 = color1 end
            local ht = thickness * 0.5
        
            -- 右
            render.gradient(
                vector(hw + offset, hh - ht), vector(hw + size, hh + ht),
                color2, color1, color2, color1
            )
            -- 左
            render.gradient(
                vector(hw - size, hh - ht), vector(hw - offset, hh + ht),
                color1, color2, color1, color2
            )
            -- 上
            if not has("Remove top line") then
                render.gradient(
                    vector(hw - ht, hh - size), vector(hw + ht, hh - offset),
                    color1, color1, color2, color2
                )
            end
            -- 下
            render.gradient(
                vector(hw - ht, hh + offset), vector(hw + ht, hh + size),
                color2, color2, color1, color1
            )
        end

        menu.callback.shutdown.Recovery_Options = function ()
            if Scope_Overlay:get() == "Remove All" then
                Scope_Overlay:set(def)
            end
        end
        

    end
}

local function fun()
    Function.Camera_Animation()
    Function.Aspect_Ratio()
    Function.AX()
    Function.Damage_indicator()
    Function.batter_scope()
end
fun()

events.render:set(function ()
    Set_visibility_callback()
    menu.callback.render.callback_on_render()
    menu.callback.render.DrawCrosshairs()
    menu.callback.render.DrawHitNumber()
    if not menu.Gui.Scope.enabled:get() and Scope_Overlay:get() == "Remove All" then
        Scope_Overlay:set(def)
    end
end)

events.createmove:set(function (cmd)
    menu.callback.createmove.callback_on_createmove(cmd)
end)

events.override_view:set(function (view)
    menu.callback.override_view.callback_on_view(view)
end)

events.shutdown:set(function()
    cvar["cl_lagcompensation"]:int(1)
    menu.callback.shutdown.Recovery_Options()
end)