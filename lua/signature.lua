local signature_is_visible = false
local signature_win_id = nil
local has_run_setup = false

-- TODO: Move this to utils/
local function is_signature_window(win_id)
	local buf_id = vim.api.nvim_win_get_buf(win_id)

	local filetype = vim.api.nvim_get_option_value('filetype', {})
	if filetype == 'lsp-signature-help' then
		return true
	end

	local lines = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)
	local content = table.concat(lines, '\n')

	if content:match("Parameters:") or content:match("%(.*%)") then
		return true
	end

	return false
end

-- TODO: Move this to utils/ & pass signature_win_id, signature_is_visible as args
local get_winid_if_sig_help = function()
	local wins = vim.api.nvim_list_wins()
	for _, win_id in ipairs(wins) do
		if vim.api.nvim_win_is_valid(win_id) and
			vim.api.nvim_win_get_config(win_id).relative ~= "" then
			if is_signature_window(win_id) then
				signature_win_id = win_id
				signature_is_visible = true
				break
			end
		end
	end
end

local M = {}

-- close_when_typing,
-- show_on_insert_enter
local default_opts = {
	close_when_typing = false,
	-- TODO: Actually use this field
	show_on_insert_enter = false,
}

local user_opts = {}

M.setup = function(opts)
	opts = opts or {}
	opts = vim.tbl_deep_extend('force', default_opts, opts)
	user_opts = opts
	vim.api.nvim_create_autocmd({ "WinNew" }, {
		callback = get_winid_if_sig_help
	})

	local close_events = nil
	if user_opts.close_when_typing then
		close_events = {
			'CursorMoved',
			'CursorMovedI',
			'InsertCharPre'
		}
	else
		close_events = { 'CursorMoved' }
	end

	vim.api.nvim_create_autocmd(close_events, {
		callback = function()
			if signature_is_visible and signature_win_id then
				signature_is_visible = false
				signature_win_id = nil
			end
		end
	})

	has_run_setup = true
end

-- Closes the signature help window
M.close_signature = function()
	if not has_run_setup then
		vim.notify("You must run require('signature').setup(opts) before using signature.nvim", vim.log.levels.ERROR)
		return
	end

	if signature_win_id then
		vim.api.nvim_win_close(signature_win_id, true)
		signature_is_visible = false
		signature_win_id = nil
	end
end

-- Opens the signature help window
--@param opts? vim.lsp.buf.signature_help.Opts (:h vim.lsp.buf.signature_help.Opts)
--
-- opts defaults to:
-- opts = { border = 'rounded' }
M.open_signature = function(opts)
	if not has_run_setup then
		vim.notify("You must run require('signature').setup(opts) before using signature.nvim", vim.log.levels.ERROR)
		return
	end

	opts = opts or {}

	local signature_help_config = {
		border = 'rounded',
	}

	signature_help_config = vim.tbl_deep_extend('force', signature_help_config, opts)

	if signature_help_config.focusable then
		vim.notify(
			"You have set focusable = true within opts, be aware that this will break require('signature').toggle_signature(). If you would like to use require('signature').toggle_signature(), set focusable = false",
			vim.log.levels.WARN)
	end

	if user_opts.close_when_typing then
		signature_help_config.close_events = {
			'CursorMoved',
			'CursorMovedI',
			'InsertCharPre'
		}
	else
		signature_help_config.close_events = {
			'CursorMoved'
		}
	end

	vim.lsp.buf.signature_help(signature_help_config)
end

-- Toggles the signature help window, i.e., opens it if the signature window is not currently open, or
-- closes it if the signature help window is already open
--@param opts? vim.lsp.buf.signature_help.Opts (:h vim.lsp.buf.signature_help.Opts)
--
-- opts defaults to:
-- opts = { border = 'rounded' }
M.toggle_signature = function(opts)
	if not has_run_setup then
		vim.notify("You must run require('signature').setup(opts) before using signature.nvim", vim.log.levels.ERROR)
		return
	end

	if signature_is_visible and signature_win_id ~= nil then
		if vim.api.nvim_win_is_valid(signature_win_id) then
			M.close_signature()
		end
	else
		M.open_signature(opts)
	end
end

return M
