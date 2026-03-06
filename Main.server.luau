local Root = script.Parent

local Config = require(Root.Config)
local UI = require(Root.UI)
local Connection = require(Root.Connection)

UI.init(plugin)

UI.toggleButton.Click:Connect(function()
	UI.widget.Enabled = not UI.widget.Enabled
end)

UI.connectBtn.MouseButton1Click:Connect(function()
	local state = Config.state
	if state.isConnected or state.isReconnecting then
		Connection.disconnect()
	else
		Connection.connect(UI.codeInput.Text)
	end
end)

UI.codeInput.FocusLost:Connect(function(enterPressed)
	local state = Config.state
	if enterPressed and not state.isConnected and not state.isReconnecting then
		Connection.connect(UI.codeInput.Text)
	end
end)
