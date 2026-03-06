local Root = script:FindFirstAncestor("Metain")
local Context = require(Root.Context)

local ScriptCmds = require(script.Parent.ScriptCmds)
local InstanceCmds = require(script.Parent.InstanceCmds)
local PropertyCmds = require(script.Parent.PropertyCmds)

local handlers = {
	read_script = ScriptCmds.read_script,
	create_script = ScriptCmds.create_script,
	update_script = ScriptCmds.update_script,
	edit_script = ScriptCmds.edit_script,
	create_instance = InstanceCmds.create_instance,
	create_ui = InstanceCmds.create_ui,
	rename = InstanceCmds.rename,
	move = InstanceCmds.move,
	delete = InstanceCmds.delete,
	clone = InstanceCmds.clone,
	set_property = PropertyCmds.set_property,
	set_properties = PropertyCmds.set_properties,
	add_tag = PropertyCmds.add_tag,
	remove_tag = PropertyCmds.remove_tag,
	set_attribute = PropertyCmds.set_attribute,
	get_attributes = PropertyCmds.get_attributes,
	undo = PropertyCmds.undo,
}

local function handleCommand(data: {[string]: any}): {[string]: any}
	local cmd = data.type

	if cmd == "ping" then
		return {success = true, message = "pong"}
	end

	if cmd == "get_context" then
		local context = Context.getContext(data.scope)
		return {success = true, context = context, message = "Context retrieved"}
	end

	local handler = handlers[cmd]
	if handler then
		return handler(data)
	end

	return {success = false, message = "Unknown command: " .. tostring(cmd)}
end

return handleCommand
