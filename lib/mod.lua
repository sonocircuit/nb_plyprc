-- polyperc (voice limited + mod section) - nb editon v.1.0 @sonoCircuit

local mu = require 'musicutil'
local md = require 'core/mods'
local vx = require 'voice'

local NUM_VOICES = 6

---------------- osc msgs ----------------

local function init_nb_plyprc()
  osc.send({ "localhost", 57120 }, "/nb_plyprc/init")
end

local function free_nb_plyprc()
  osc.send({ "localhost", 57120 }, "/nb_plyprc/free")
end

local function dont_panic()
  osc.send({ "localhost", 57120 }, "/nb_plyprc/panic")
end

local function set_param(key, val)
  osc.send({ "localhost", 57120 }, "/nb_plyprc/set_param", {key, val})
end


---------------- functions ----------------

local function round_form(param, quant, form)
  return(util.round(param, quant)..form)
end

local function add_plyprc_params()
  params:add_group("nb_plyprc_group", "plyprc", 17)
  params:hide("nb_plyprc_group")

  params:add_separator("nb_plyprc_levels", "levels")
  params:add_control("nb_plyprc_amp", "amp", controlspec.new(0, 1, "lin", 0, 0.8), function(param) return round_form(param:get() * 100, 1, "%") end)
  params:set_action("nb_plyprc_amp", function(val) set_param('amp', val) end)

  params:add_control("nb_plyprc_spread", "spread", controlspec.new(0, 1, "lin", 0, 0), function(param) return round_form(param:get() * 100, 1, "%") end)
  params:set_action("nb_plyprc_spread", function(val) set_param('spread', val) end)

  params:add_control("nb_plyprc_send_a", "send a", controlspec.new(0, 1, "lin", 0, 0), function(param) return round_form(param:get() * 100, 1, "%") end)
  params:set_action("nb_plyprc_send_a", function(val) set_param('sendA', val) end)
  
  params:add_control("nb_plyprc_send_b", "send b", controlspec.new(0, 1, "lin", 0, 0), function(param) return round_form(param:get() * 100, 1, "%") end)
  params:set_action("nb_plyprc_send_b", function(val) set_param('sendB', val) end)

  params:add_separator("nb_plyprc_sound", "sound")

  params:add_control("nb_plyprc_decay", "decay", controlspec.new(0.01, 10, "exp", 0, 1.2), function(param) return (round_form(param:get(),0.01," s")) end)
  params:set_action("nb_plyprc_decay", function(val) set_param('decay', val) end)

  params:add_control("nb_plyprc_pulse_width", "pulse width", controlspec.new(0.1, 0.9, "lin", 0, 0.5), function(param) return round_form(param:get() * 100, 1, "%") end)
  params:set_action("nb_plyprc_pulse_width", function(val) set_param('pw', val) end)

  params:add_control("nb_plyprc_cutoff_lpf", "cutoff", controlspec.new(20, 18000, "exp", 0, 1200), function(param) return round_form(param:get(), 1, " hz") end)
  params:set_action("nb_plyprc_cutoff_lpf", function(val) set_param('cutoff_lpf', val) end)

  params:add_control("nb_plyprc_cutoff_track", "tracking", controlspec.new(-1, 1, "lin", 0, 0, "", 1/200), function(param) return round_form(param:get() * 100, 1, "%") end)
  params:set_action("nb_plyprc_cutoff_track", function(val) set_param('track_lpf', val) end)

  params:add_control("nb_plyprc_res_lpf", "resonance", controlspec.new(0, 1, "lin", 0, 0.1), function(param) return round_form(param:get() * 100, 1, "%") end)
  params:set_action("nb_plyprc_res_lpf", function(val) set_param('res_lpf', val) end)

  params:add_separator("nb_plyprc_mod", "modulation")

  params:add_control("nb_plyprc_mod_amt", "mod amt [map me]", controlspec.new(0, 1, "lin", 0, 0), function(param) return round_form(param:get() * 100, 1, "%") end)
  params:set_action("nb_plyprc_mod_amt", function(val) set_param('mod_depth', val) end)
  params:set_save("nb_plyprc_mod_amt", false)

  params:add_control("nb_plyprc_pw_mod", "pulse width", controlspec.new(-1, 1, "lin", 0, 0, "", 1/200), function(param) return round_form(param:get() * 100, 1, "%") end)
  params:set_action("nb_plyprc_pw_mod", function(val) set_param('pw_mod', val) end)

  params:add_control("nb_plyprc_cutoff_mod", "cutoff", controlspec.new(-1, 1, "lin", 0, 0, "", 1/200), function(param) return round_form(param:get() * 100, 1, "%") end)
  params:set_action("nb_plyprc_cutoff_mod", function(val) set_param('cut_mod', val) end)

  params:add_control("nb_plyprc_send_a_mod", "send a", controlspec.new(-1, 1, "lin", 0, 0, "", 1/200), function(param) return round_form(param:get() * 100, 1, "%") end)
  params:set_action("nb_plyprc_send_a_mod", function(val) set_param('sendA_mod', val) end)

  params:add_control("nb_plyprc_send_b_mod", "send b", controlspec.new(-1, 1, "lin", 0, 0, "", 1/200), function(param) return round_form(param:get() * 100, 1, "%") end)
  params:set_action("nb_plyprc_send_b_mod", function(val) set_param('sendB_mod', val) end)
end


---------------- nb player ----------------

function add_nb_plyprc_player()
  local player = {
    alloc = vx.new(NUM_VOICES, 2),
    slot = {},
    is_active = false,
    init_clk = nil
  }

  function player:active()
    if self.name ~= nil then
      if self.clk ~= nil then
        clock.cancel(self.clk)
      end
      self.clk = clock.run(function()
        clock.sleep(0.2)
        if not self.is_active then
          self.is_active = true
          params:show("nb_plyprc_group")
          if md.is_loaded("fx") == false then
            params:hide("nb_plyprc_send_a")
            params:hide("nb_plyprc_send_b")
            params:hide("nb_plyprc_send_a_mod")
            params:hide("nb_plyprc_send_b_mod")
          end
          _menu.rebuild_params()
        end
      end)
    end
  end

  function player:inactive()
    if self.name ~= nil then
      if self.clk ~= nil then
        clock.cancel(self.clk)
      end
      self.clk = clock.run(function()
        clock.sleep(0.2)
        if self.is_active then
          self.is_active = false
          dont_panic()
          params:hide("nb_plyprc_group")
          _menu.rebuild_params()
        end
      end)
    end
  end

  function player:stop_all()
    osc.send({ "localhost", 57120 }, "/nb_plyprc/panic", {})
  end

  function player:modulate(val)
    params:set("nb_plyprc_mod_depth", val)
  end

  function player:set_slew(s)
  end

  function player:describe()
    return {
      name = "plyprc",
      supports_bend = false,
      supports_slew = false
    }
  end

  function player:pitch_bend(note, amount)
  end

  function player:modulate_note(note, key, value) 
  end

  function player:note_on(note, vel)
    local freq = mu.note_num_to_freq(note)
    local slot = self.slot[note]
    if slot == nil then
      slot = self.alloc:get()
    end
    local voice = slot.id - 1 -- sc is zero indexed!
    self.slot[note] = slot
    osc.send({ "localhost", 57120 }, "/nb_plyprc/trig", {voice, freq, vel})
  end

  function player:note_off(note)
    local slot = self.slot[note]
    if slot ~= nil then
      self.slot[note] = nil
    end
  end

  function player:add_params()
    add_plyprc_params()
  end

  if note_players == nil then
    note_players = {}
  end
  note_players["plyprc"] = player
end


---------------- mod zone ----------------

function pre_init()
  init_nb_plyprc()
  add_nb_plyprc_player()
end

md.hook.register("script_pre_init", "nb_plyprc pre init", pre_init)
