local M = {}

M.is_signature_window = function(win_id)
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

M.get_winid_if_sig_help = function()
	local wins = vim.api.nvim_list_wins()
	for _, win_id in ipairs(wins) do
		if vim.api.nvim_win_is_valid(win_id) and
			vim.api.nvim_win_get_config(win_id).relative ~= "" then
			if M.is_signature_window(win_id) then
				return win_id, true
			end
		end
	end
end

return M
