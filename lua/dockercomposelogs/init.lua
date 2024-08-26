local pickers = require("telescope.pickers")
local config = require("telescope.config").values
local finders = require("telescope.finders")
local previewers = require("telescope.previewers")
local utils = require("telescope.previewers.utils")

local M = {}

---@class dockercomposelogs.Config
local defaults = {
	no_log_prefix = true, -- show the service name in the logs
	show_timestamps = false, -- show the timestamps in the logs
	use_color = true, -- colorize the output in the previewer pane
	logs_since = 10, -- how far in the logs do you want to go? This is in minutes. Must be a valid number. 2 to 60 accepted
}

---@param opts dockercomposelogs.Config
local show_dockercompose_logs = function(opts)
	-- Now you can use opts.no_log_prefix, opts.show_timestamps, etc.
	-- They will have the default values if not specified in the input opts

	local log_prefix = opts.no_log_prefix and "--no-log-prefix" or ""
	local timestamps = opts.show_timestamps and "--timestamps" or ""
	local color = opts.use_color and "" or "--no-color"
	local logs_since = tonumber(opts.logs_since) or defaults.logs_since

	if logs_since < 2 or logs_since > 60 then
		vim.notify(
			string.format(
				"Invalid logs_since value: %s. Must be between 2 and 60. Using default: %s",
				logs_since,
				defaults.logs_since
			),
			vim.log.levels.INFO
		)
		logs_since = defaults.logs_since
	end

	local since_minutes = string.format("--since %dm", logs_since)

	pickers
		.new(opts, {
			finder = finders.new_async_job({
				command_generator = function()
					return { "docker", "compose", "ps", "--format", "json", "--services" }
				end,
				entry_maker = function(entry)
					local parsed = entry
					if parsed then
						return {
							display = parsed,
							ordinal = parsed,
							value = parsed,
						}
					end
				end,
			}),
			sorter = config.generic_sorter(opts),
			previewer = previewers.new_buffer_previewer({
				title = "Docker Image logs",
				define_preview = function(self, entry)
					local cmd = string.format(
						"docker compose logs %s %s %s %s %s",
						entry.value,
						log_prefix,
						timestamps,
						color,
						since_minutes
					)
					local handle = io.popen(cmd)
					if not handle then
						vim.api.nvim_err_writeln("Error: Could not fetch your logs")
						return
					end

					local logs = handle:read("*a")
					handle:close()
					vim.api.nvim_buf_set_lines(
						self.state.bufnr,
						0,
						0,
						true,
						vim.tbl_flatten({
							opts.use_color and "```lua" or "",
							vim.split(logs, "\n"),
							opts.use_color and "```" or "",
						})
					)

					if opts.use_color then
						utils.highlighter(self.state.bufnr, "markdown")
					end
				end,
			}),
		})
		:find()
end

---@param opts? dockercomposelogs.Config
M.setup = function(opts)
	vim.api.nvim_create_user_command("DockerComposeLogs", function()
		show_dockercompose_logs(vim.tbl_deep_extend("force", defaults, opts or {}))
	end, {})
end

return M
